import 'dart:convert';

import 'package:get/get.dart';
import 'package:stategetx/models/app_user.dart';
import 'package:stategetx/models/recurring_transaction.dart';
import 'package:stategetx/services/api_service.dart';
import 'package:stategetx/services/auth_service.dart';
import 'package:stategetx/services/storage_service.dart';

class RecurringTransactionRepository extends GetxService {
  static const String _legacyStorageKey = 'recurring_transactions';
  static const String _legacyStorageOwnerKey = 'recurring_transactions_owner';

  late final ApiService _apiService;
  late final StorageService _storageService;
  late final AuthService _authService;

  final RxList<RecurringTransaction> recurringTransactions =
      <RecurringTransaction>[].obs;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _storageService = Get.find<StorageService>();
    _authService = Get.find<AuthService>();
    ever<AppUser?>(_authService.currentUser, (_) => loadRecurringTransactions());
    loadRecurringTransactions();
  }

  Future<void> loadRecurringTransactions() async {
    if (_authService.currentUser.value == null) {
      recurringTransactions.clear();
      return;
    }

    try {
      final response = await _apiService.get(ApiConstants.recurringTransactions);
      final decoded = response.data;
      if (decoded is List) {
        recurringTransactions.assignAll(
          decoded
              .whereType<Map>()
              .map(
                (json) => RecurringTransaction.fromJson(
                  Map<String, dynamic>.from(json),
                ),
              )
              .toList()
            ..sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth)),
        );
        await _persist();
        return;
      }
    } catch (_) {
      // Fallback below.
    }

    await _migrateLegacyRecurringIfNeeded();
    recurringTransactions.assignAll(
      _decode(_storageService.getValue<String>(_scopedStorageKey())),
    );
    recurringTransactions.sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));
  }

  Future<void> addRecurringTransaction(RecurringTransaction transaction) async {
    try {
      final response = await _apiService.post(
        ApiConstants.recurringTransactions,
        data: transaction.toJson(),
      );
      final saved = RecurringTransaction.fromJson(
        Map<String, dynamic>.from(response.data),
      );
      final index = recurringTransactions.indexWhere((item) => item.id == saved.id);
      if (index == -1) {
        recurringTransactions.add(saved);
      } else {
        recurringTransactions[index] = saved;
      }
    } catch (_) {
      final index = recurringTransactions.indexWhere(
        (item) => item.id == transaction.id,
      );
      if (index == -1) {
        recurringTransactions.add(transaction);
      } else {
        recurringTransactions[index] = transaction;
      }
    }

    recurringTransactions.sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));
    await _persist();
  }

  Future<void> deleteRecurringTransaction(String id) async {
    try {
      await _apiService.delete('${ApiConstants.recurringTransactions}/$id');
    } catch (_) {
      // Keep local state consistent.
    }

    recurringTransactions.removeWhere((item) => item.id == id);
    await _persist();
  }

  Future<void> _persist() async {
    await _storageService.setValue<String>(
      _scopedStorageKey(),
      jsonEncode(recurringTransactions.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> _migrateLegacyRecurringIfNeeded() async {
    if (_storageService.hasKey(_scopedStorageKey())) return;

    final ownerKey = _currentUserStorageKey();
    final legacyOwner = _storageService.getValue<String>(_legacyStorageOwnerKey);
    if (legacyOwner != null && legacyOwner != ownerKey) {
      return;
    }

    final decoded = _decode(
      _storageService.getValue<String>(_legacyStorageKey),
    );
    if (decoded.isEmpty) return;

    for (final item in decoded) {
      try {
        await _apiService.post(
          ApiConstants.recurringTransactions,
          data: item.toJson(),
        );
      } catch (_) {
        // Continue seeding what we can.
      }
    }

    await _storageService.setValue<String>(
      _scopedStorageKey(),
      jsonEncode(decoded.map((item) => item.toJson()).toList()),
    );
    await _storageService.setValue<String>(_legacyStorageOwnerKey, ownerKey);
  }

  String _scopedStorageKey() =>
      'recurring_transactions_${_currentUserStorageKey()}';

  String _currentUserStorageKey() {
    final user = _authService.currentUser.value;
    final userId = user?.id?.trim();
    final email = user?.email?.trim().toLowerCase();
    final base = userId != null && userId.isNotEmpty
        ? userId
        : (email != null && email.isNotEmpty ? email : 'anonymous');
    return base.replaceAll(RegExp(r'[^a-zA-Z0-9_\-@.]'), '_');
  }

  List<RecurringTransaction> _decode(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) {
      return <RecurringTransaction>[];
    }
    final decoded = jsonDecode(rawValue);
    if (decoded is! List) return <RecurringTransaction>[];
    return decoded
        .whereType<Map>()
        .map(
          (json) =>
              RecurringTransaction.fromJson(Map<String, dynamic>.from(json)),
        )
        .toList()
      ..sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));
  }
}
