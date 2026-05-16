import 'dart:convert';

import 'package:get/get.dart';
import 'package:stategetx/models/app_transaction.dart';
import 'package:stategetx/services/api_service.dart';
import 'package:stategetx/services/storage_service.dart';

class TransactionRepository extends GetxService {
  late final ApiService _apiService;
  late final StorageService _storageService;

  static const String _transactionsKey = 'local_transactions';

  final RxList<AppTransaction> transactions = <AppTransaction>[].obs;
  final RxBool isLoaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _storageService = Get.find<StorageService>();
  }

  Future<List<AppTransaction>> getTransactions({bool forceRefresh = false}) async {
    if (isLoaded.value && !forceRefresh) {
      return transactions.toList();
    }

    return syncTransactions(forceRefresh: forceRefresh);
  }

  Future<List<AppTransaction>> syncTransactions({bool forceRefresh = true}) async {
    List<AppTransaction> resolvedTransactions = [];

    if (forceRefresh) {
      try {
        final response = await _apiService.get(ApiConstants.transactions);
        if (response.statusCode == 200) {
          resolvedTransactions = _parseTransactionList(response.data);
          await _saveLocalTransactions(resolvedTransactions);
        }
      } catch (_) {
        resolvedTransactions = await _getLocalTransactions();
      }
    } else {
      resolvedTransactions = await _getLocalTransactions();
      if (resolvedTransactions.isEmpty) {
        try {
          final response = await _apiService.get(ApiConstants.transactions);
          if (response.statusCode == 200) {
            resolvedTransactions = _parseTransactionList(response.data);
            await _saveLocalTransactions(resolvedTransactions);
          }
        } catch (_) {
          resolvedTransactions = await _getLocalTransactions();
        }
      }
    }

    transactions.assignAll(_sortTransactions(resolvedTransactions));
    isLoaded.value = true;
    return transactions.toList();
  }

  Future<AppTransaction> createTransaction(AppTransaction transaction) async {
    AppTransaction createdTransaction = transaction.copyWith(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
    );

    try {
      final response = await _apiService.post(
        ApiConstants.transactions,
        data: transaction.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        createdTransaction = _parseTransactionResponse(response.data);
      } else {
        throw Exception('Failed to create transaction');
      }
    } catch (_) {
      // Fall back to local persistence.
    }

    await _upsertLocalTransaction(createdTransaction);
    await syncTransactions(forceRefresh: false);
    return createdTransaction;
  }

  Future<bool> deleteTransaction(String id) async {
    try {
      final response = await _apiService.delete('${ApiConstants.transactions}/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete transaction');
      }
    } catch (_) {
      // Keep local state consistent even when API is unavailable.
    }

    final localTransactions = await _getLocalTransactions();
    localTransactions.removeWhere((transaction) => transaction.id == id);
    await _saveLocalTransactions(localTransactions);
    await syncTransactions(forceRefresh: false);
    return true;
  }

  List<AppTransaction> _parseTransactionList(dynamic data) {
    late final List<dynamic> rawTransactions;

    if (data is Map<String, dynamic>) {
      final nestedTransactions = data['transactions'] ?? data['data'];
      if (nestedTransactions is List) {
        rawTransactions = nestedTransactions;
      } else {
        rawTransactions = const [];
      }
    } else if (data is List) {
      rawTransactions = data;
    } else {
      throw Exception('Unexpected transaction response format');
    }

    return rawTransactions
        .whereType<Map>()
        .map((json) => AppTransaction.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  AppTransaction _parseTransactionResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      final transactionJson = data['transaction'] ?? data['data'] ?? data;
      if (transactionJson is Map) {
        return AppTransaction.fromJson(Map<String, dynamic>.from(transactionJson));
      }
    }

    throw Exception('Unexpected transaction create response format');
  }

  Future<List<AppTransaction>> _getLocalTransactions() async {
    final rawTransactions = _storageService.getValue<String>(_transactionsKey);
    if (rawTransactions == null || rawTransactions.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(rawTransactions);
    if (decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map>()
        .map((json) => AppTransaction.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  Future<void> _saveLocalTransactions(
    List<AppTransaction> transactions,
  ) async {
    final encodedTransactions = jsonEncode(
      transactions.map((transaction) => transaction.toJson()).toList(),
    );
    await _storageService.setValue<String>(_transactionsKey, encodedTransactions);
  }

  Future<void> _upsertLocalTransaction(AppTransaction transaction) async {
    final localTransactions = await _getLocalTransactions();
    final updatedTransactions = List<AppTransaction>.from(localTransactions)
      ..removeWhere((item) => item.id == transaction.id)
      ..add(transaction);
    await _saveLocalTransactions(_sortTransactions(updatedTransactions));
  }

  List<AppTransaction> _sortTransactions(List<AppTransaction> items) {
    final sortedItems = List<AppTransaction>.from(items)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sortedItems;
  }
}
