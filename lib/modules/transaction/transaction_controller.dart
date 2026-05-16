import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stategetx/core/base_controller.dart';
import 'package:stategetx/models/app_category.dart';
import 'package:stategetx/models/app_transaction.dart';
import 'package:stategetx/models/credit_card.dart';
import 'package:stategetx/repositoryies/category_repository.dart';
import 'package:stategetx/repositoryies/credit_card_repository.dart';
import 'package:stategetx/repositoryies/transaction_repository.dart';

class TransactionController extends BaseController {
  final CategoryRepository _categoryRepository = Get.find<CategoryRepository>();
  final TransactionRepository _transactionRepository =
      Get.find<TransactionRepository>();
  final CreditCardRepository _creditCardRepository =
      Get.find<CreditCardRepository>();

  final categories = <AppCategory>[].obs;
  final selectedCategoryId = ''.obs;
  final operationType = 'expense'.obs; // 'income', 'expense', or 'card-payment'
  final amount = 0.0.obs;
  final title = ''.obs;
  final description = ''.obs;
  final selectedDate = DateTime.now().obs;

  // Ödeme yöntemi seçimi
  final paymentMethod = Rx<String?>(null); // 'cash', 'bank', or cardId

  // Kart işlemleri için
  final selectedCardForPaymentId = Rx<String?>(null);
  final cardPaymentAmount = 0.0.obs;
  final cardPaymentAmountController = TextEditingController();

  final titleTextController = TextEditingController();
  final descriptionTextController = TextEditingController();
  final amountTextController = TextEditingController();

  RxList<AppTransaction> get transactions =>
      _transactionRepository.transactions;
  RxList<CreditCardModel> get creditCards => _creditCardRepository.cards;

  CreditCardModel? get selectedCardForPayment {
    if (selectedCardForPaymentId.value == null) return null;
    try {
      return creditCards.firstWhere(
        (card) => card.id == selectedCardForPaymentId.value,
      );
    } catch (e) {
      return null;
    }
  }

  List<AppCategory> get filteredCategories {
    return categories.where((category) {
      return category.type == operationType.value &&
          category.name != 'Kart Borcu Ödeme'; // Gizle normal giderlerde
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    titleTextController.addListener(
      () => title.value = titleTextController.text,
    );
    descriptionTextController.addListener(
      () => description.value = descriptionTextController.text,
    );
    amountTextController.addListener(() {
      amount.value =
          double.tryParse(amountTextController.text.replaceAll(',', '.')) ??
          0.0;
    });
    cardPaymentAmountController.addListener(() {
      cardPaymentAmount.value =
          double.tryParse(
            cardPaymentAmountController.text.replaceAll(',', '.'),
          ) ??
          0.0;
    });
    ever(operationType, (_) => _syncCategorySelection());
    loadCategories();
    loadTransactions();
  }

  @override
  void onClose() {
    titleTextController.dispose();
    descriptionTextController.dispose();
    amountTextController.dispose();
    cardPaymentAmountController.dispose();
    super.onClose();
  }

  void _syncCategorySelection() {
    final available = filteredCategories;
    if (available.isEmpty) {
      selectedCategoryId.value = '';
      return;
    }

    if (!available.any((category) => category.id == selectedCategoryId.value)) {
      selectedCategoryId.value = available.first.id ?? '';
    }
  }

  Future<void> loadCategories() async {
    setLoading(true);
    try {
      final result = await _categoryRepository.getCategories();
      categories.value = result;
      _syncCategorySelection();
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Kategoriler yüklenemedi: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadTransactions() async {
    setLoading(true);
    try {
      await _transactionRepository.getTransactions(forceRefresh: false);
    } catch (e) {
      Get.snackbar(
        'Hata',
        'İşlemler yüklenemedi: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setLoading(false);
    }
  }

  Future<void> createTransaction() async {
    // Kart ödeme işlemi
    if (operationType.value == 'card-payment') {
      if (selectedCardForPaymentId.value == null ||
          cardPaymentAmount.value <= 0) {
        Get.snackbar(
          'Hata',
          'Lütfen kart ve tutar seçin',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      setLoading(true);
      try {
        final cardId = selectedCardForPaymentId.value!;
        await _creditCardRepository.payCardDebt(
          cardId,
          cardPaymentAmount.value,
        );

        // Transaction oluştur
        final cardName = selectedCardForPayment?.name ?? 'Kart Ödeme';
        final transaction = AppTransaction(
          id: '',
          title: 'Kart Borcu Ödeme - $cardName',
          description: null,
          amount: cardPaymentAmount.value,
          category: 'Kart Borcu Ödeme',
          date: selectedDate.value,
          isIncome: false,
          selectedCardId: cardId,
          isInstallment: false,
        );

        await _transactionRepository.createTransaction(transaction);
        await loadTransactions();
        resetForm();

        Get.snackbar(
          'Başarılı',
          'Kart borcu ödenmiştir',
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        Get.snackbar(
          'Hata',
          'İşlem başarısız oldu: $e',
          snackPosition: SnackPosition.BOTTOM,
        );
      } finally {
        setLoading(false);
      }
      return;
    }

    // Normal gelir/gider işlemi
    if (selectedCategoryId.value.isEmpty ||
        amount.value <= 0 ||
        title.value.trim().isEmpty ||
        paymentMethod.value == null) {
      Get.snackbar(
        'Hata',
        'Lütfen tüm alanları doldurun',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setLoading(true);
    try {
      final selectedCategory = categories.firstWhere(
        (cat) => cat.id == selectedCategoryId.value,
      );

      final isCardPayment =
          paymentMethod.value != null &&
          paymentMethod.value != 'cash' &&
          paymentMethod.value != 'bank';
      final selectedCardId = isCardPayment ? paymentMethod.value : null;

      final newTransaction = AppTransaction(
        id: '',
        title: title.value.trim(),
        description: description.value.isNotEmpty ? description.value : null,
        amount: amount.value,
        category: selectedCategory.name ?? '',
        date: selectedDate.value,
        isIncome: operationType.value == 'income',
        selectedCardId: selectedCardId,
        isInstallment: false,
      );

      // Kredi kartından ödeme yapılıyorsa
      if (isCardPayment) {
        final cardId = selectedCardId!;
        await _creditCardRepository.chargeCardPurchase(cardId, amount.value);
      }

      await _transactionRepository.createTransaction(newTransaction);
      await loadTransactions();
      resetForm();

      Get.snackbar(
        'Başarılı',
        'İşlem başarıyla oluşturuldu',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Hata',
        'İşlem oluşturulamadı: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setLoading(false);
    }
  }

  Future<void> deleteTransaction(String id) async {
    setLoading(true);
    try {
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

  Future<void> createCategory(String name) async {
    if (name.trim().isEmpty) {
      Get.snackbar(
        'Hata',
        'Kategori adı boş olamaz',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setLoading(true);
    try {
      final newCategory = AppCategory(
        name: name.trim(),
        type: operationType.value,
      );

      await _categoryRepository.createCategory(newCategory);
      await loadCategories();

      Get.snackbar(
        'Başarılı',
        'Kategori başarıyla oluşturuldu',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Kategori oluşturulamadı: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setLoading(false);
    }
  }

  void resetForm() {
    title.value = '';
    description.value = '';
    amount.value = 0.0;
    selectedDate.value = DateTime.now();
    selectedCategoryId.value = '';
    paymentMethod.value = null;
    selectedCardForPaymentId.value = null;
    cardPaymentAmount.value = 0.0;
    titleTextController.clear();
    descriptionTextController.clear();
    amountTextController.clear();
    cardPaymentAmountController.clear();
  }

  /// Kart seçildiğinde, bu ayın ödeme tutarını otomatik doldur
  void setCardPaymentAmountToThisMonth() {
    final card = selectedCardForPayment;
    if (card != null) {
      cardPaymentAmount.value = card.currentStatementDebt;
      cardPaymentAmountController.text = cardPaymentAmount.value
          .toStringAsFixed(2);
    }
  }
}
