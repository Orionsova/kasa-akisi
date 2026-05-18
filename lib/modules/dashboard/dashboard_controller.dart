import 'package:get/get.dart';
import 'package:stategetx/core/base_controller.dart';
import 'package:stategetx/models/app_transaction.dart';
import 'package:stategetx/models/credit_card.dart';
import 'package:stategetx/models/investment.dart';
import 'package:stategetx/models/recurring_transaction.dart';
import 'package:stategetx/repositoryies/credit_card_repository.dart';
import 'package:stategetx/repositoryies/investment_repository.dart';
import 'package:stategetx/repositoryies/recurring_transaction_repository.dart';
import 'package:stategetx/repositoryies/transaction_repository.dart';

class DashboardController extends BaseController {
  final TransactionRepository _transactionRepository =
      Get.find<TransactionRepository>();
  final RecurringTransactionRepository _recurringRepository =
      Get.find<RecurringTransactionRepository>();
  final CreditCardRepository _creditCardRepository =
      Get.find<CreditCardRepository>();
  final InvestmentRepository _investmentRepository =
      Get.find<InvestmentRepository>();

  RxList<AppTransaction> get transactions => _transactionRepository.transactions;
  RxList<RecurringTransaction> get recurringTransactions =>
      _recurringRepository.recurringTransactions;
  RxList<CreditCardModel> get cards => _creditCardRepository.cards;
  RxList<InvestmentModel> get investments => _investmentRepository.investments;

  @override
  void onReady() {
    super.onReady();
    refreshTransactions();
  }

  Future<void> refreshTransactions() async {
    try {
      setLoading(true);
      await _transactionRepository.syncTransactions(forceRefresh: false);
      await _recurringRepository.loadRecurringTransactions();
      await _creditCardRepository.loadCards();
      await _investmentRepository.loadInvestments();
    } finally {
      setLoading(false);
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      setLoading(true);
      final transaction = transactions.firstWhereOrNull((item) => item.id == id);
      if (transaction != null) {
        await _revertCardEffect(transaction);
      }
      await _transactionRepository.deleteTransaction(id);
      Get.snackbar(
        'Silindi',
        'İşlem kaydı kaldırıldı',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Hata',
        'İşlem silinemedi: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setLoading(false);
    }
  }

  double get totalIncome => transactions
      .where((transaction) => transaction.isIncome)
      .fold(0, (sum, transaction) => sum + transaction.amount);

  double get totalExpense => transactions
      .where((transaction) => !transaction.isIncome && transaction.affectsCashBalance)
      .fold(0, (sum, transaction) => sum + transaction.amount);

  double get balance => totalIncome - totalExpense;

  double get totalCardDebt =>
      cards.fold<double>(0, (sum, card) => sum + card.currentDebt);

  double get recurringExpenseTotal => recurringTransactions
      .where((item) => !item.isIncome)
      .fold(0, (sum, item) => sum + item.amount);

  double get totalInvestmentValue =>
      investments.fold(0, (sum, item) => sum + item.currentValue);

  List<AppTransaction> get currentMonthTransactions {
    final now = DateTime.now();
    return transactions.where((transaction) {
      return transaction.date.year == now.year &&
          transaction.date.month == now.month;
    }).toList();
  }

  List<AppTransaction> get currentMonthCardExpenses => currentMonthTransactions
      .where((transaction) => transaction.isCardExpense)
      .toList();

  List<AppTransaction> get currentMonthCardPayments => currentMonthTransactions
      .where((transaction) => transaction.isCardDebtPayment)
      .toList();

  double get currentMonthCardSpendingTotal => currentMonthCardExpenses.fold<double>(
    0,
    (sum, transaction) => sum + transaction.amount,
  );

  double get currentMonthCardPaymentTotal => currentMonthCardPayments.fold<double>(
    0,
    (sum, transaction) => sum + transaction.amount,
  );

  String cardLabelFor(String? cardId) {
    if (cardId == null || cardId.trim().isEmpty) {
      return 'Kart';
    }

    final card = cards.firstWhereOrNull((item) => item.id == cardId);
    return card?.name ?? 'Kart';
  }

  List<RecurringTransaction> get upcomingRecurring {
    final today = DateTime.now();
    return recurringTransactions.where((item) => item.dayOfMonth >= today.day).toList()
      ..sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));
  }

  List<AppTransaction> get recentTransactions => transactions.take(5).toList();

  Future<void> _revertCardEffect(AppTransaction transaction) async {
    final cardId = transaction.selectedCardId;
    if (cardId == null || cardId.trim().isEmpty) {
      return;
    }

    if (transaction.isCardExpense) {
      await _creditCardRepository.payCardDebt(cardId, transaction.amount);
      return;
    }

    if (transaction.isCardDebtPayment) {
      await _creditCardRepository.chargeCardPurchase(cardId, transaction.amount);
    }
  }
}
