import 'dart:convert';

import 'package:get/get.dart';
import 'package:stategetx/models/recurring_transaction.dart';
import 'package:stategetx/services/api_service.dart';
import 'package:stategetx/services/storage_service.dart';

class RecurringTransactionRepository extends GetxService {
  static const String _legacyStorageKey = 'recurring_transactions';

  late final ApiService _apiService;
  late final StorageService _storageService;

  final RxList<RecurringTransaction> recurringTransactions =
      <RecurringTransaction>[].obs;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _storageService = Get.find<StorageService>();
    loadRecurringTransactions();
  }

  Future<void> loadRecurringTransactions() async {
    try {
      final response = await _apiService.get(ApiConstants.recurringTransactions);
      final decoded = response.data;
      if (decoded is! List) {
        recurringTransactions.clear();
      } else {
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
      }

      if (recurringTransactions.isEmpty) {
        await _migrateLegacyRecurringIfNeeded();
      }
    } catch (_) {
      final decoded = _decodeLegacy(
        _storageService.getValue<String>(_legacyStorageKey),
      );
      if (decoded.isEmpty) {
        recurringTransactions.assignAll(_defaultRecurringTransactions());
      } else {
        recurringTransactions.assignAll(decoded);
      }
    }
  }

  Future<void> addRecurringTransaction(RecurringTransaction transaction) async {
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
    recurringTransactions.sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));
  }

  Future<void> deleteRecurringTransaction(String id) async {
    await _apiService.delete('${ApiConstants.recurringTransactions}/$id');
    recurringTransactions.removeWhere((item) => item.id == id);
  }

  Future<void> _migrateLegacyRecurringIfNeeded() async {
    final decoded = _decodeLegacy(
      _storageService.getValue<String>(_legacyStorageKey),
    );
    final items = decoded.isNotEmpty ? decoded : _defaultRecurringTransactions();
    for (final item in items) {
      await _apiService.post(
        ApiConstants.recurringTransactions,
        data: item.toJson(),
      );
    }
    recurringTransactions.assignAll(items);
    recurringTransactions.sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));
  }

  List<RecurringTransaction> _decodeLegacy(String? rawValue) {
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

  List<RecurringTransaction> _defaultRecurringTransactions() {
    final now = DateTime.now();
    return [
      RecurringTransaction(
        id: 'default-salary',
        title: 'Maaş',
        category: 'Gelir',
        amount: 45000,
        dayOfMonth: 1,
        isIncome: true,
        isSubscription: false,
        startDate: DateTime(now.year, now.month, 1),
      ),
      RecurringTransaction(
        id: 'default-netflix',
        title: 'Netflix',
        category: 'Abonelik',
        amount: 229.99,
        dayOfMonth: 12,
        isIncome: false,
        isSubscription: true,
        startDate: DateTime(now.year, now.month, 12),
      ),
    ];
  }
}
