import 'dart:convert';

import 'package:get/get.dart';
import 'package:stategetx/models/credit_card.dart';
import 'package:stategetx/models/credit_score_snapshot.dart';
import 'package:stategetx/services/storage_service.dart';

class CreditCardRepository extends GetxService {
  static const String _storageKey = 'credit_cards';
  static const String _scoreHistoryStorageKey = 'credit_card_score_history';

  late final StorageService _storageService;

  final RxList<CreditCardModel> cards = <CreditCardModel>[].obs;
  final RxList<CreditScoreSnapshot> scoreHistory = <CreditScoreSnapshot>[].obs;

  @override
  void onInit() {
    super.onInit();
    _storageService = Get.find<StorageService>();
    loadCards();
  }

  Future<void> loadCards() async {
    await _loadScoreHistory();
    final rawValue = _storageService.getValue<String>(_storageKey);
    if (rawValue == null || rawValue.isEmpty) {
      cards.assignAll(_defaultCards());
      await _persist();
      await _recordScoreSnapshotIfNeeded(forceIfEmpty: true);
      return;
    }

    final decoded = jsonDecode(rawValue);
    if (decoded is! List) {
      cards.assignAll(_defaultCards());
      await _persist();
      await _recordScoreSnapshotIfNeeded(forceIfEmpty: true);
      return;
    }

    cards.assignAll(
      decoded
          .whereType<Map>()
          .map(
            (json) => CreditCardModel.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList(),
    );
    await _recordScoreSnapshotIfNeeded(forceIfEmpty: true);
  }

  Future<void> addCard(CreditCardModel card) async {
    cards.add(card);
    await _persist();
  }

  Future<void> saveCard(CreditCardModel card) async {
    final index = cards.indexWhere((item) => item.id == card.id);
    if (index == -1) {
      cards.add(card);
    } else {
      cards[index] = card;
    }
    await _persist();
    await _recordScoreSnapshotIfNeeded();
  }

  Future<void> addInstallment(
    String cardId,
    InstallmentPlan installment,
  ) async {
    final index = cards.indexWhere((card) => card.id == cardId);
    if (index == -1) {
      return;
    }

    final card = cards[index];
    final updatedInstallments = List<InstallmentPlan>.from(card.installments)
      ..removeWhere((item) => item.id == installment.id)
      ..add(installment);
    updatedInstallments.sort(
      (left, right) => left.firstPaymentDate.compareTo(right.firstPaymentDate),
    );
    cards[index] = card.copyWith(installments: updatedInstallments);
    await _persist();
    await _recordScoreSnapshotIfNeeded();
  }

  Future<void> deleteInstallment(String cardId, String installmentId) async {
    final index = cards.indexWhere((card) => card.id == cardId);
    if (index == -1) {
      return;
    }

    final card = cards[index];
    cards[index] = card.copyWith(
      installments: List<InstallmentPlan>.from(card.installments)
        ..removeWhere((item) => item.id == installmentId),
    );
    await _persist();
    await _recordScoreSnapshotIfNeeded();
  }

  Future<void> addFuturePeriodPayment(
    String cardId,
    FuturePeriodPayment payment,
  ) async {
    final index = cards.indexWhere((card) => card.id == cardId);
    if (index == -1) {
      return;
    }

    final card = cards[index];
    cards[index] = card.copyWith(
      futurePeriodPayments: [...card.futurePeriodPayments, payment],
    );
    await _persist();
    await _recordScoreSnapshotIfNeeded();
  }

  Future<void> adjustAvailableLimit(String cardId, double delta) async {
    final index = cards.indexWhere((card) => card.id == cardId);
    if (index == -1) {
      return;
    }

    final card = cards[index];
    final nextAvailableLimit = (card.availableLimit + delta).clamp(
      0,
      card.limit,
    );
    cards[index] = card.copyWith(availableLimit: nextAvailableLimit.toDouble());
    await _persist();
    await _recordScoreSnapshotIfNeeded();
  }

  /// Kredi kartından alışveriş yaptığında limitten düş ve borca ekle
  Future<void> chargeCardPurchase(String cardId, double amount) async {
    final index = cards.indexWhere((card) => card.id == cardId);
    if (index == -1) {
      return;
    }

    final card = cards[index];
    // Limit'ten düş (mevcut borcu artır)
    final newAvailableLimit = (card.availableLimit - amount).clamp(
      0,
      card.limit,
    );

    cards[index] = card.copyWith(availableLimit: newAvailableLimit.toDouble());
    await _persist();
    await _recordScoreSnapshotIfNeeded();
  }

  /// Kart borcunun ödendiğinde limitini artır
  Future<void> payCardDebt(String cardId, double paymentAmount) async {
    final index = cards.indexWhere((card) => card.id == cardId);
    if (index == -1) {
      return;
    }

    final card = cards[index];
    // Ödenen tutarı limite ekle (mevcut borcu azalt)
    final newAvailableLimit = (card.availableLimit + paymentAmount).clamp(
      0,
      card.limit,
    );

    cards[index] = card.copyWith(availableLimit: newAvailableLimit.toDouble());
    await _persist();
    await _recordScoreSnapshotIfNeeded();
  }

  Future<void> deleteCard(String id) async {
    cards.removeWhere((item) => item.id == id);
    await _persist();
    await _recordScoreSnapshotIfNeeded();
  }

  Future<void> _persist() async {
    final encoded = jsonEncode(cards.map((item) => item.toJson()).toList());
    await _storageService.setValue<String>(_storageKey, encoded);
  }

  Future<void> _loadScoreHistory() async {
    final rawValue = _storageService.getValue<String>(_scoreHistoryStorageKey);
    if (rawValue == null || rawValue.isEmpty) {
      scoreHistory.clear();
      return;
    }

    final decoded = jsonDecode(rawValue);
    if (decoded is! List) {
      scoreHistory.clear();
      return;
    }

    scoreHistory.assignAll(
      decoded
          .whereType<Map>()
          .map(
            (json) =>
                CreditScoreSnapshot.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList()
        ..sort((left, right) => right.createdAt.compareTo(left.createdAt)),
    );
  }

  Future<void> _persistScoreHistory() async {
    final encoded = jsonEncode(
      scoreHistory.map((item) => item.toJson()).toList(),
    );
    await _storageService.setValue<String>(_scoreHistoryStorageKey, encoded);
  }

  Future<void> _recordScoreSnapshotIfNeeded({bool forceIfEmpty = false}) async {
    final totalLimit = cards.fold<double>(0, (sum, card) => sum + card.limit);
    final totalAvailableLimit = cards.fold<double>(
      0,
      (sum, card) => sum + card.availableLimit,
    );
    final currentStatementDebt = cards.fold<double>(
      0,
      (sum, card) => sum + card.currentStatementDebt,
    );
    final score = _creditScore(totalLimit, currentStatementDebt);

    final last = scoreHistory.isEmpty ? null : scoreHistory.first;
    final shouldSkip =
        !forceIfEmpty &&
        last != null &&
        last.score == score &&
        last.totalLimit == totalLimit &&
        last.availableLimit == totalAvailableLimit &&
        last.currentStatementDebt == currentStatementDebt;

    if (shouldSkip) {
      return;
    }

    final snapshot = CreditScoreSnapshot(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      score: score,
      totalLimit: totalLimit,
      availableLimit: totalAvailableLimit,
      currentStatementDebt: currentStatementDebt,
    );

    scoreHistory.insert(0, snapshot);
    if (scoreHistory.length > 24) {
      scoreHistory.removeRange(24, scoreHistory.length);
    }
    await _persistScoreHistory();
  }

  int _creditScore(double totalLimit, double currentStatementDebt) {
    if (totalLimit <= 0) {
      return 100;
    }
    final ratio = (currentStatementDebt / totalLimit).clamp(0, 1);
    final score = (100 - (ratio * 100)).round();
    return score.clamp(0, 100).toInt();
  }

  List<CreditCardModel> _defaultCards() {
    return [
      CreditCardModel(
        id: 'default-card',
        name: 'Ana kart',
        lastFourDigits: '4821',
        cardholderNameOverride: null,
        isActive: true,
        limit: 80000,
        availableLimit: 51132,
        dueDay: 13,
        statementDay: 3,
        paymentGraceDays: 10,
        colorHex: 'cobalt_blue',
        shapeKey: 'diagonal_gloss',
        installments: [
          InstallmentPlan(
            id: 'default-phone',
            title: 'Telefon',
            totalAmount: 18000,
            monthlyAmount: 3000,
            totalInstallments: 6,
            remainingInstallments: 4,
            firstPaymentDate: DateTime(2026, 3, 10),
          ),
        ],
        futurePeriodPayments: const [],
      ),
    ];
  }
}
