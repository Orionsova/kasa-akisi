import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stategetx/core/base_controller.dart';
import 'package:stategetx/core/formatters.dart';
import 'package:stategetx/models/credit_card.dart';
import 'package:stategetx/models/credit_score_snapshot.dart';
import 'package:stategetx/repositoryies/credit_card_repository.dart';
import 'package:stategetx/services/auth_service.dart';

class CreditCardsController extends BaseController {
  final CreditCardRepository _creditCardRepository =
      Get.find<CreditCardRepository>();
  final AuthService _authService = Get.find<AuthService>();

  final nameController = TextEditingController();
  final cardholderNameController = TextEditingController();
  final lastFourDigitsController = TextEditingController();
  final limitController = TextEditingController();
  final availableLimitController = TextEditingController();
  final statementDayController = TextEditingController();
  final paymentGraceDaysController = TextEditingController();
  final installmentTitleController = TextEditingController();
  final installmentTotalController = TextEditingController();
  final installmentMonthlyController = TextEditingController();
  final installmentCountController = TextEditingController();
  final installmentRemainingController = TextEditingController();
  final futurePaymentTitleController = TextEditingController();
  final futurePaymentAmountController = TextEditingController();
  final futurePaymentInstallmentCountController = TextEditingController();
  final futurePaymentRemainingController = TextEditingController();
  final selectedInstallmentFirstPayment = DateTime.now().obs;
  final selectedFuturePaymentMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  ).obs;
  final isActiveCard = true.obs;
  final useCustomCardholderName = false.obs;
  final selectedColorHex = 'graphite_metal'.obs;
  final selectedShapeKey = 'diagonal_gloss'.obs;

  RxList<CreditCardModel> get cards => _creditCardRepository.cards;
  RxList<CreditScoreSnapshot> get scoreHistory => _creditCardRepository.scoreHistory;
  String get cardholderName {
    final user = _authService.currentUser.value;
    final fullName = '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
    if (fullName.isNotEmpty) {
      return fullName.toUpperCase();
    }
    final fallback = user?.email?.split('@').first.trim() ?? '';
    if (fallback.isNotEmpty) {
      return fallback.toUpperCase();
    }
    return 'KART SAHIBI';
  }

  String cardholderNameForCard(CreditCardModel card) {
    final custom = card.cardholderNameOverride?.trim() ?? '';
    if (custom.isNotEmpty) {
      return custom.toUpperCase();
    }
    return cardholderName;
  }

  @override
  void onInit() {
    super.onInit();
    cardholderNameController.text = cardholderName;
  }

  @override
  void onClose() {
    nameController.dispose();
    cardholderNameController.dispose();
    lastFourDigitsController.dispose();
    limitController.dispose();
    availableLimitController.dispose();
    statementDayController.dispose();
    paymentGraceDaysController.dispose();
    installmentTitleController.dispose();
    installmentTotalController.dispose();
    installmentMonthlyController.dispose();
    installmentCountController.dispose();
    installmentRemainingController.dispose();
    futurePaymentTitleController.dispose();
    futurePaymentAmountController.dispose();
    futurePaymentInstallmentCountController.dispose();
    futurePaymentRemainingController.dispose();
    super.onClose();
  }

  Future<void> loadCards() => _creditCardRepository.loadCards();

  double get totalDebt =>
      cards.fold(0, (sum, card) => sum + card.currentDebt);
  double get totalCurrentStatementDebt =>
      cards.fold(0, (sum, card) => sum + card.currentStatementDebt);
  double get totalNextPeriodDebt =>
      cards.fold(0, (sum, card) => sum + card.nextPeriodDebt);

  double get totalLimit => cards.fold(0, (sum, card) => sum + card.limit);

  double get availableLimit =>
      cards.fold(0, (sum, card) => sum + card.availableLimit);
  double get totalRemainingDebt =>
      cards.fold(0, (sum, card) => sum + card.currentDebt);
  double get monthlyPaymentRatio =>
      totalLimit == 0 ? 0 : (totalCurrentStatementDebt / totalLimit).clamp(0, 1).toDouble();
  double get utilizationRate =>
      totalLimit == 0 ? 0 : ((totalLimit - availableLimit) / totalLimit).clamp(0, 1);
  int get score => _creditScore(monthlyPaymentRatio);

  CreditCardModel? get topSpendingCard {
    if (cards.isEmpty) {
      return null;
    }
    final ranked = cards.toList()
      ..sort((left, right) => right.currentStatementDebt.compareTo(left.currentStatementDebt));
    return ranked.first;
  }

  List<CreditCardModel> get rankedCardsBySpending {
    final ranked = cards.toList()
      ..sort((left, right) => right.currentStatementDebt.compareTo(left.currentStatementDebt));
    return ranked;
  }

  int get highRiskCardCount =>
      cards.where((card) => card.limit > 0 && (card.currentDebt / card.limit) >= 0.7).length;

  String get scoreHeadline {
    if (score >= 85) {
      return 'Kart görünümün oldukça dengeli';
    }
    if (score >= 65) {
      return 'Kontrol sende ama alan daralıyor';
    }
    if (score >= 45) {
      return 'Kart yükü dikkat istiyor';
    }
    return 'Ekstre tarafı sıkışık görünüyor';
  }

  List<String> get scoreInsights {
    final insights = <String>[];
    final topCard = topSpendingCard;

    if (topCard != null) {
      insights.add(
        'En yüksek bu ay yük ${topCard.name} kartında: ${AppFormatters.currency(topCard.currentStatementDebt)}',
      );
    }

    if (totalLimit > 0) {
      insights.add(
        'Toplam limitin %${(monthlyPaymentRatio * 100).round()} kadarı bu ay ekstreye dönmüş durumda.',
      );
    }

    if (highRiskCardCount > 0) {
      insights.add(
        '$highRiskCardCount kartta borç oranı %70 üzerine çıktı; bu kartları önce hafifletmek daha sağlıklı olur.',
      );
    } else {
      insights.add('Kart borç dağılımı şu an kritik eşiklerin altında görünüyor.');
    }

    if (availableLimit > 0) {
      insights.add(
        'Kullanılabilir toplam limit ${AppFormatters.currency(availableLimit)} seviyesinde.',
      );
    }

    return insights;
  }

  List<({CreditCardModel card, InstallmentPlan installment})> get allInstallments {
    final items = <({CreditCardModel card, InstallmentPlan installment})>[];
    for (final card in cards) {
      for (final installment in card.installments) {
        items.add((card: card, installment: installment));
      }
    }
    items.sort(
      (left, right) => right.installment.monthlyAmount.compareTo(
        left.installment.monthlyAmount,
      ),
    );
    return items;
  }

  void _syncInstallmentFieldsFromInputs() {
    final total = AppFormatters.parseCurrencyInput(installmentTotalController.text);
    final monthly = AppFormatters.parseCurrencyInput(
      installmentMonthlyController.text,
    );
    final count = int.tryParse(installmentCountController.text);

    if ((total == null || total <= 0) &&
        monthly != null &&
        monthly > 0 &&
        count != null &&
        count > 0) {
      installmentTotalController.text = AppFormatters.amountInput(monthly * count);
      return;
    }

    if ((monthly == null || monthly <= 0) &&
        total != null &&
        total > 0 &&
        count != null &&
        count > 0) {
      installmentMonthlyController.text = AppFormatters.amountInput(total / count);
      return;
    }

    if ((count == null || count <= 0) &&
        total != null &&
        total > 0 &&
        monthly != null &&
        monthly > 0) {
      installmentCountController.text = (total / monthly).round().toString();
    }
  }

  void clearInstallmentFieldsIfOneIsEmpty() {
    if (installmentTotalController.text.trim().isEmpty ||
        installmentMonthlyController.text.trim().isEmpty ||
        installmentCountController.text.trim().isEmpty) {
      installmentTotalController.clear();
      installmentMonthlyController.clear();
      installmentCountController.clear();
    }
  }

  Future<void> saveCard({String? cardId}) async {
    final limit = AppFormatters.parseCurrencyInput(limitController.text);
    final availableLimit = AppFormatters.parseCurrencyInput(
      availableLimitController.text,
    );
    final statementDay = int.tryParse(statementDayController.text);
    final paymentGraceDays = int.tryParse(paymentGraceDaysController.text);

    if (nameController.text.trim().isEmpty ||
        (lastFourDigitsController.text.trim().isNotEmpty &&
            lastFourDigitsController.text.trim().length != 4) ||
        limit == null ||
        availableLimit == null ||
        statementDay == null ||
        paymentGraceDays == null) {
      Get.snackbar('Hata', 'Kart bilgilerini eksiksiz doldurun');
      return;
    }

    if (availableLimit > limit) {
      Get.snackbar('Hata', 'Mevcut limit, toplam limitten büyük olamaz');
      return;
    }

    final existingCard = cardId == null
        ? null
        : cards.firstWhereOrNull((item) => item.id == cardId);

    final card = CreditCardModel(
      id: cardId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: nameController.text.trim(),
      lastFourDigits: lastFourDigitsController.text.trim(),
      cardholderNameOverride: useCustomCardholderName.value
          ? cardholderNameController.text.trim()
          : null,
      isActive: isActiveCard.value,
      limit: limit,
      availableLimit: availableLimit,
      dueDay: statementDay + paymentGraceDays,
      statementDay: statementDay,
      paymentGraceDays: paymentGraceDays,
      colorHex: selectedColorHex.value,
      shapeKey: selectedShapeKey.value,
      installments: existingCard?.installments ?? const [],
      futurePeriodPayments: existingCard?.futurePeriodPayments ?? const [],
    );

    await _creditCardRepository.saveCard(card);
    clearForm();
    Get.snackbar(
      'Başarılı',
      cardId == null ? 'Kredi kartı eklendi' : 'Kredi kartı güncellendi',
    );
  }

  Future<void> deleteCard(String id) async {
    await _creditCardRepository.deleteCard(id);
    Get.snackbar('Silindi', 'Kart kaldırıldı');
  }

  Future<void> saveInstallment(
    String cardId, {
    String? installmentId,
  }) async {
    _syncInstallmentFieldsFromInputs();

    final totalAmount = AppFormatters.parseCurrencyInput(
      installmentTotalController.text,
    );
    final monthlyAmount = AppFormatters.parseCurrencyInput(
      installmentMonthlyController.text,
    );
    final totalInstallments = int.tryParse(installmentCountController.text);
    final remainingInstallments = int.tryParse(
      installmentRemainingController.text,
    );

    if (installmentTitleController.text.trim().isEmpty ||
        totalAmount == null ||
        monthlyAmount == null ||
        totalInstallments == null ||
        remainingInstallments == null) {
      Get.snackbar('Hata', 'Taksit bilgilerini eksiksiz doldurun');
      return;
    }

    if (remainingInstallments > totalInstallments) {
      Get.snackbar('Hata', 'Kalan taksit, toplam taksitten büyük olamaz');
      return;
    }

    final installment = InstallmentPlan(
      id: installmentId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: installmentTitleController.text.trim(),
      totalAmount: totalAmount,
      monthlyAmount: monthlyAmount,
      totalInstallments: totalInstallments,
      remainingInstallments: remainingInstallments,
      firstPaymentDate: selectedInstallmentFirstPayment.value,
    );

    await _creditCardRepository.addInstallment(cardId, installment);
    clearInstallmentForm();
    Get.snackbar('Başarılı', 'Taksit planı kaydedildi');
  }

  Future<void> deleteInstallment(String cardId, String installmentId) async {
    await _creditCardRepository.deleteInstallment(cardId, installmentId);
    Get.snackbar('Silindi', 'Taksit kaydı kaldırıldı');
  }

  Future<void> addFuturePeriodPayment(String cardId) async {
    final amount = AppFormatters.parseCurrencyInput(
      futurePaymentAmountController.text,
    );
    final totalInstallments = futurePaymentInstallmentCountController.text.trim().isEmpty
        ? null
        : int.tryParse(futurePaymentInstallmentCountController.text);
    final remainingInstallments = futurePaymentRemainingController.text.trim().isEmpty
        ? null
        : int.tryParse(futurePaymentRemainingController.text);

    if (futurePaymentTitleController.text.trim().isEmpty ||
        amount == null) {
      Get.snackbar('Hata', 'Gelecek dönem bilgilerini eksiksiz doldurun');
      return;
    }

    final payment = FuturePeriodPayment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: futurePaymentTitleController.text.trim(),
      monthLabel: AppFormatters.monthYearLabel(selectedFuturePaymentMonth.value),
      amount: amount,
      totalInstallments: totalInstallments,
      remainingInstallments: remainingInstallments,
    );

    await _creditCardRepository.addFuturePeriodPayment(cardId, payment);
    clearFuturePaymentForm();
    Get.snackbar('Başarılı', 'Gelecek dönem ödemesi eklendi');
  }

  void clearForm() {
    nameController.clear();
    cardholderNameController.text = cardholderName;
    lastFourDigitsController.clear();
    limitController.clear();
    availableLimitController.clear();
    statementDayController.text = '3';
    paymentGraceDaysController.text = '10';
    isActiveCard.value = true;
    useCustomCardholderName.value = false;
    selectedColorHex.value = 'graphite_metal';
    selectedShapeKey.value = 'diagonal_gloss';
  }

  void fillCardForm(CreditCardModel card) {
    nameController.text = card.name;
    cardholderNameController.text = card.cardholderNameOverride ?? cardholderName;
    lastFourDigitsController.text = card.lastFourDigits;
    limitController.text = AppFormatters.amountInput(card.limit);
    availableLimitController.text = AppFormatters.amountInput(card.availableLimit);
    statementDayController.text = card.statementDay.toString();
    paymentGraceDaysController.text = card.paymentGraceDays.toString();
    isActiveCard.value = card.isActive;
    useCustomCardholderName.value = (card.cardholderNameOverride?.trim().isNotEmpty ?? false);
    selectedColorHex.value = card.colorHex;
    selectedShapeKey.value = card.shapeKey;
  }

  void selectCardColor(String colorKey) {
    selectedColorHex.value = colorKey;
  }

  void selectCardShape(String shapeKey) {
    selectedShapeKey.value = shapeKey;
  }

  void clearInstallmentForm() {
    installmentTitleController.clear();
    installmentTotalController.clear();
    installmentMonthlyController.clear();
    installmentCountController.clear();
    installmentRemainingController.clear();
    selectedInstallmentFirstPayment.value = DateTime.now();
  }

  void fillInstallmentForm(InstallmentPlan installment) {
    installmentTitleController.text = installment.title;
    installmentTotalController.text = AppFormatters.amountInput(
      installment.totalAmount,
    );
    installmentMonthlyController.text = AppFormatters.amountInput(
      installment.monthlyAmount,
    );
    installmentCountController.text = installment.totalInstallments.toString();
    installmentRemainingController.text =
        installment.remainingInstallments.toString();
    selectedInstallmentFirstPayment.value = installment.firstPaymentDate;
  }

  void clearFuturePaymentForm() {
    futurePaymentTitleController.clear();
    futurePaymentAmountController.clear();
    futurePaymentInstallmentCountController.clear();
    futurePaymentRemainingController.clear();
    selectedFuturePaymentMonth.value = DateTime(
      DateTime.now().year,
      DateTime.now().month,
    );
  }

  int _creditScore(double ratio) {
    final score = (100 - (ratio.clamp(0, 1) * 100)).round();
    return score.clamp(0, 100).toInt();
  }
}
