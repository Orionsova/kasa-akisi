import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:stategetx/models/app_user.dart';
import 'package:stategetx/models/credit_card.dart';
import 'package:stategetx/models/credit_score_snapshot.dart';
import 'package:stategetx/services/api_service.dart';
import 'package:stategetx/services/auth_service.dart';
import 'package:stategetx/services/storage_service.dart';

class CreditCardRepository extends GetxService {
  static const String _legacyStorageKey = 'credit_cards';
  static const String _legacyScoreHistoryStorageKey = 'credit_card_score_history';
  static const String _legacyStorageOwnerKey = 'credit_cards_owner';
  static const String _legacyScoreOwnerKey = 'credit_card_score_history_owner';

  late final ApiService _apiService;
  late final StorageService _storageService;
  late final AuthService _authService;

  final RxList<CreditCardModel> cards = <CreditCardModel>[].obs;
  final RxList<CreditScoreSnapshot> scoreHistory = <CreditScoreSnapshot>[].obs;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _storageService = Get.find<StorageService>();
    _authService = Get.find<AuthService>();
    ever<AppUser?>(_authService.currentUser, (_) => loadCards());
    loadCards();
  }

  Future<void> loadCards() async {
    if (_authService.currentUser.value == null) {
      cards.clear();
      scoreHistory.clear();
      return;
    }

    await _loadScoreHistory();

    try {
      final response = await _apiService.get(ApiConstants.creditCards);
      final decoded = response.data;
      if (decoded is! List) {
        cards.clear();
      } else {
        cards.assignAll(
          decoded
              .whereType<Map>()
              .map(
                (json) => CreditCardModel.fromJson(
                  Map<String, dynamic>.from(json),
                ),
              )
              .toList(),
        );
      }

      if (cards.isEmpty) {
        await _migrateLegacyCardsIfNeeded();
      } else {
        await _recordScoreSnapshotIfNeeded(forceIfEmpty: true);
      }
    } catch (_) {
      await _loadLegacyCardsFallback();
      await _loadLegacyScoreHistoryFallback();
    }
  }

  Future<void> addCard(CreditCardModel card) => saveCard(card);

  Future<void> saveCard(CreditCardModel card) async {
    CreditCardModel saved = card;

    try {
      final response = await _apiService.post(
        ApiConstants.creditCards,
        data: card.toJson(),
      );
      saved = CreditCardModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (_) {
      // Keep the app usable when the remote credit-card API is not deployed yet.
    }

    final index = cards.indexWhere((item) => item.id == saved.id);
    if (index == -1) {
      cards.add(saved);
    } else {
      cards[index] = saved;
    }
    await _persistCards();
    await _recordScoreSnapshotIfNeeded();
  }

  Future<void> addInstallment(String cardId, InstallmentPlan installment) async {
    final index = cards.indexWhere((card) => card.id == cardId);
    if (index == -1) return;

    final card = cards[index];
    final updatedInstallments = List<InstallmentPlan>.from(card.installments)
      ..removeWhere((item) => item.id == installment.id)
      ..add(installment);
    updatedInstallments.sort(
      (left, right) => left.firstPaymentDate.compareTo(right.firstPaymentDate),
    );
    await saveCard(card.copyWith(installments: updatedInstallments));
  }

  Future<void> deleteInstallment(String cardId, String installmentId) async {
    final index = cards.indexWhere((card) => card.id == cardId);
    if (index == -1) return;

    final card = cards[index];
    await saveCard(
      card.copyWith(
        installments: List<InstallmentPlan>.from(card.installments)
          ..removeWhere((item) => item.id == installmentId),
      ),
    );
  }

  Future<void> addFuturePeriodPayment(
    String cardId,
    FuturePeriodPayment payment,
  ) async {
    final index = cards.indexWhere((card) => card.id == cardId);
    if (index == -1) return;

    final card = cards[index];
    await saveCard(
      card.copyWith(
        futurePeriodPayments: [...card.futurePeriodPayments, payment],
      ),
    );
  }

  Future<void> adjustAvailableLimit(String cardId, double delta) async {
    final index = cards.indexWhere((card) => card.id == cardId);
    if (index == -1) return;

    final card = cards[index];
    final nextAvailableLimit = (card.availableLimit + delta).clamp(
      0,
      card.limit,
    );
    await saveCard(
      card.copyWith(availableLimit: nextAvailableLimit.toDouble()),
    );
  }

  Future<void> chargeCardPurchase(String cardId, double amount) async {
    await adjustAvailableLimit(cardId, -amount);
  }

  Future<void> payCardDebt(String cardId, double paymentAmount) async {
    await adjustAvailableLimit(cardId, paymentAmount);
  }

  Future<void> deleteCard(String id) async {
    try {
      await _apiService.delete('${ApiConstants.creditCards}/$id');
    } on DioException catch (_) {
      // Preserve local behavior when backend route is unavailable.
    }
    cards.removeWhere((item) => item.id == id);
    await _persistCards();
    await _recordScoreSnapshotIfNeeded();
  }

  Future<void> _loadScoreHistory() async {
    try {
      final response = await _apiService.get(ApiConstants.creditCardScoreHistory);
      final decoded = response.data;
      if (decoded is! List) {
        scoreHistory.clear();
        return;
      }

      scoreHistory.assignAll(
        decoded
            .whereType<Map>()
            .map(
              (json) => CreditScoreSnapshot.fromJson(
                Map<String, dynamic>.from(json),
              ),
            )
            .toList()
          ..sort((left, right) => right.createdAt.compareTo(left.createdAt)),
      );
      await _persistScoreHistory();
    } catch (_) {
      scoreHistory.clear();
    }
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

    if (shouldSkip) return;

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

    try {
      await _apiService.post(
        ApiConstants.creditCardScoreHistory,
        data: snapshot.toJson(),
      );
    } on DioException {
      // Keep local score timeline usable on transient API failures.
    }
  }

  int _creditScore(double totalLimit, double currentStatementDebt) {
    if (totalLimit <= 0) return 100;
    final ratio = (currentStatementDebt / totalLimit).clamp(0, 1);
    return (100 - (ratio * 100)).round().clamp(0, 100).toInt();
  }

  Future<void> _persistCards() async {
    await _storageService.setValue<String>(
      _scopedCardsStorageKey(),
      jsonEncode(cards.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> _persistScoreHistory() async {
    await _storageService.setValue<String>(
      _scopedScoreStorageKey(),
      jsonEncode(scoreHistory.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> _migrateLegacyCardsIfNeeded() async {
    final ownerKey = _currentUserStorageKey();
    final rawValue = _storageService.getValue<String>(_legacyStorageKey);
    final migratedCards = _decodeCards(rawValue);
    final cardsToSeed = migratedCards.isNotEmpty ? migratedCards : _defaultCards();

    for (final card in cardsToSeed) {
      try {
        await _apiService.post(ApiConstants.creditCards, data: card.toJson());
      } on DioException catch (_) {
        // Continue with local seed when backend route is unavailable.
      }
    }

    final legacyScores = _decodeScores(
      _storageService.getValue<String>(_legacyScoreHistoryStorageKey),
    );
    for (final item in legacyScores) {
      await _apiService.post(
        ApiConstants.creditCardScoreHistory,
        data: item.toJson(),
      );
    }

    cards.assignAll(cardsToSeed);
    if (legacyScores.isNotEmpty) {
      scoreHistory.assignAll(legacyScores);
    }
    await _persistCards();
    await _persistScoreHistory();
    await _storageService.setValue<String>(_legacyStorageOwnerKey, ownerKey);
    await _storageService.setValue<String>(_legacyScoreOwnerKey, ownerKey);
    await _recordScoreSnapshotIfNeeded(forceIfEmpty: true);
  }

  Future<void> _loadLegacyCardsFallback() async {
    final decoded = _decodeCards(_storageService.getValue<String>(_legacyStorageKey));
    if (decoded.isEmpty) {
      cards.assignAll(_defaultCards());
    } else {
      cards.assignAll(decoded);
    }
    await _persistCards();
    await _recordScoreSnapshotIfNeeded(forceIfEmpty: true);
  }

  Future<void> _loadLegacyScoreHistoryFallback() async {
    final decoded = _decodeScores(
      _storageService.getValue<String>(_legacyScoreHistoryStorageKey),
    );
    if (decoded.isNotEmpty) {
      scoreHistory.assignAll(decoded);
      await _persistScoreHistory();
    }
  }

  String _scopedCardsStorageKey() =>
      'credit_cards_${_currentUserStorageKey()}';

  String _scopedScoreStorageKey() =>
      'credit_card_score_history_${_currentUserStorageKey()}';

  String _currentUserStorageKey() {
    final user = _authService.currentUser.value;
    final userId = user?.id?.trim();
    final email = user?.email?.trim().toLowerCase();
    final base = userId != null && userId.isNotEmpty
        ? userId
        : (email != null && email.isNotEmpty ? email : 'anonymous');
    return base.replaceAll(RegExp(r'[^a-zA-Z0-9_\-@.]'), '_');
  }

  List<CreditCardModel> _decodeCards(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) return <CreditCardModel>[];
    final decoded = jsonDecode(rawValue);
    if (decoded is! List) return <CreditCardModel>[];
    return decoded
        .whereType<Map>()
        .map((json) => CreditCardModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  List<CreditScoreSnapshot> _decodeScores(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) return <CreditScoreSnapshot>[];
    final decoded = jsonDecode(rawValue);
    if (decoded is! List) return <CreditScoreSnapshot>[];
    return decoded
        .whereType<Map>()
        .map(
          (json) => CreditScoreSnapshot.fromJson(
            Map<String, dynamic>.from(json),
          ),
        )
        .toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
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
