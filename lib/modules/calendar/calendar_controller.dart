import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stategetx/core/base_controller.dart';
import 'package:stategetx/models/app_transaction.dart';
import 'package:stategetx/models/credit_card.dart';
import 'package:stategetx/models/recurring_transaction.dart';
import 'package:stategetx/repositoryies/credit_card_repository.dart';
import 'package:stategetx/repositoryies/recurring_transaction_repository.dart';
import 'package:stategetx/repositoryies/transaction_repository.dart';

class CalendarController extends BaseController {
  final TransactionRepository _transactionRepository =
      Get.find<TransactionRepository>();
  final RecurringTransactionRepository _recurringRepository =
      Get.find<RecurringTransactionRepository>();
  final CreditCardRepository _creditCardRepository =
      Get.find<CreditCardRepository>();

  final selectedMonth = DateTime(DateTime.now().year, DateTime.now().month).obs;
  final selectedDate = DateTime.now().obs;

  final titleController = TextEditingController();
  final noteController = TextEditingController();
  final amountController = TextEditingController();
  final dayController = TextEditingController();

  final recurringType = 'expense'.obs;
  final isSubscription = false.obs;

  RxList<AppTransaction> get transactions => _transactionRepository.transactions;
  RxList<RecurringTransaction> get recurringTransactions =>
      _recurringRepository.recurringTransactions;
  RxList<CreditCardModel> get cards => _creditCardRepository.cards;

  @override
  void onInit() {
    super.onInit();
    dayController.text = DateTime.now().day.toString();
  }

  @override
  void onClose() {
    titleController.dispose();
    noteController.dispose();
    amountController.dispose();
    dayController.dispose();
    super.onClose();
  }

  Future<void> refreshAll() async {
    setLoading(true);
    try {
      await _transactionRepository.getTransactions(forceRefresh: false);
      await _recurringRepository.loadRecurringTransactions();
      await _creditCardRepository.loadCards();
    } finally {
      setLoading(false);
    }
  }

  void goToNextMonth() {
    final next = DateTime(selectedMonth.value.year, selectedMonth.value.month + 1);
    selectedMonth.value = next;
    selectedDate.value = DateTime(next.year, next.month, 1);
  }

  void goToPreviousMonth() {
    final previous = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month - 1,
    );
    selectedMonth.value = previous;
    selectedDate.value = DateTime(previous.year, previous.month, 1);
  }

  void selectDate(DateTime date) {
    selectedDate.value = date;
    selectedMonth.value = DateTime(date.year, date.month);
  }

  List<DateTime?> get visibleMonthDays {
    final firstDay = DateTime(selectedMonth.value.year, selectedMonth.value.month, 1);
    final daysInMonth =
        DateTime(selectedMonth.value.year, selectedMonth.value.month + 1, 0).day;
    final leadingEmptyDays = firstDay.weekday - 1;
    final cells = <DateTime?>[
      ...List<DateTime?>.filled(leadingEmptyDays, null),
      ...List<DateTime?>.generate(
        daysInMonth,
        (index) => DateTime(
          selectedMonth.value.year,
          selectedMonth.value.month,
          index + 1,
        ),
      ),
    ];

    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  List<DateTime> get monthDaysOnly {
    return List<DateTime>.generate(
      DateTime(selectedMonth.value.year, selectedMonth.value.month + 1, 0).day,
      (index) => DateTime(
        selectedMonth.value.year,
        selectedMonth.value.month,
        index + 1,
      ),
    );
  }

  List<AppTransaction> transactionsForDate(DateTime date) {
    return transactions.where((transaction) => _isSameDay(transaction.date, date)).toList();
  }

  List<RecurringTransaction> recurringForDate(DateTime date) {
    return recurringTransactions.where((item) {
      return item.dayOfMonth == date.day &&
          !date.isBefore(DateTime(item.startDate.year, item.startDate.month, item.startDate.day));
    }).toList();
  }

  bool hasEntriesOn(DateTime date) {
    return transactionsForDate(date).isNotEmpty ||
        recurringForDate(date).isNotEmpty ||
        cardStatementsForDate(date).isNotEmpty;
  }

  List<CreditCardModel> cardStatementsForDate(DateTime date) {
    return cards
        .where(
          (card) => card.statementDay == date.day && card.currentStatementDebt > 0,
        )
        .toList();
  }

  double totalRecurringIncomeForMonth(DateTime month) {
    return recurringTransactions
        .where((item) => item.isIncome)
        .fold(0, (sum, item) => sum + item.amount);
  }

  double totalRecurringExpenseForMonth(DateTime month) {
    return recurringTransactions
        .where((item) => !item.isIncome)
        .fold(0, (sum, item) => sum + item.amount);
  }

  List<RecurringTransaction> get upcomingRecurring {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    return recurringTransactions.where((item) {
      final occurrence = DateTime(currentMonth.year, currentMonth.month, item.dayOfMonth);
      return occurrence.isAfter(DateTime(now.year, now.month, now.day - 1));
    }).toList()
      ..sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));
  }

  Future<void> createRecurringTransaction() async {
    if (titleController.text.trim().isEmpty ||
        amountController.text.trim().isEmpty ||
        dayController.text.trim().isEmpty) {
      Get.snackbar('Hata', 'Lütfen zorunlu alanları doldurun');
      return;
    }

    final day = int.tryParse(dayController.text);
    final amount = double.tryParse(amountController.text.replaceAll(',', '.'));
    if (day == null || day < 1 || day > 31 || amount == null || amount <= 0) {
      Get.snackbar('Hata', 'Gün veya tutar bilgisi geçersiz');
      return;
    }

    final entry = RecurringTransaction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      category: isSubscription.value ? 'Abonelik' : 'Düzenli Kayıt',
      amount: amount,
      dayOfMonth: day,
      isIncome: recurringType.value == 'income',
      isSubscription: isSubscription.value,
      note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
      startDate: DateTime.now(),
    );

    await _recurringRepository.addRecurringTransaction(entry);
    clearRecurringForm();
    Get.snackbar('Başarılı', 'Düzenli kayıt eklendi');
  }

  Future<void> deleteRecurringTransaction(String id) async {
    await _recurringRepository.deleteRecurringTransaction(id);
    Get.snackbar('Silindi', 'Düzenli kayıt kaldırıldı');
  }

  void clearRecurringForm() {
    titleController.clear();
    noteController.clear();
    amountController.clear();
    dayController.text = DateTime.now().day.toString();
    recurringType.value = 'expense';
    isSubscription.value = false;
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
