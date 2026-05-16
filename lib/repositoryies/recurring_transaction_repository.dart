import 'dart:convert';

import 'package:get/get.dart';
import 'package:stategetx/models/recurring_transaction.dart';
import 'package:stategetx/services/storage_service.dart';

class RecurringTransactionRepository extends GetxService {
  static const String _storageKey = 'recurring_transactions';

  late final StorageService _storageService;

  final RxList<RecurringTransaction> recurringTransactions =
      <RecurringTransaction>[].obs;

  @override
  void onInit() {
    super.onInit();
    _storageService = Get.find<StorageService>();
    loadRecurringTransactions();
  }

  Future<void> loadRecurringTransactions() async {
    final rawValue = _storageService.getValue<String>(_storageKey);
    if (rawValue == null || rawValue.isEmpty) {
      recurringTransactions.assignAll(_defaultRecurringTransactions());
      await _persist();
      return;
    }

    final decoded = jsonDecode(rawValue);
    if (decoded is! List) {
      recurringTransactions.assignAll(_defaultRecurringTransactions());
      await _persist();
      return;
    }

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

  Future<void> addRecurringTransaction(RecurringTransaction transaction) async {
    recurringTransactions.add(transaction);
    recurringTransactions.sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));
    await _persist();
  }

  Future<void> deleteRecurringTransaction(String id) async {
    recurringTransactions.removeWhere((item) => item.id == id);
    await _persist();
  }

  Future<void> _persist() async {
    final encoded = jsonEncode(
      recurringTransactions.map((item) => item.toJson()).toList(),
    );
    await _storageService.setValue<String>(_storageKey, encoded);
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
