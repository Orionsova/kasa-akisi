import 'dart:convert';

import 'package:get/get.dart';
import 'package:stategetx/models/investment.dart';
import 'package:stategetx/services/api_service.dart';
import 'package:stategetx/services/storage_service.dart';

class InvestmentRepository extends GetxService {
  static const String _legacyStorageKey = 'investments';

  late final ApiService _apiService;
  late final StorageService _storageService;

  final RxList<InvestmentModel> investments = <InvestmentModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _storageService = Get.find<StorageService>();
    loadInvestments();
  }

  Future<void> loadInvestments() async {
    try {
      final response = await _apiService.get(ApiConstants.investments);
      final decoded = response.data;
      if (decoded is! List) {
        investments.clear();
      } else {
        investments.assignAll(
          decoded
              .whereType<Map>()
              .map(
                (json) =>
                    InvestmentModel.fromJson(Map<String, dynamic>.from(json)),
              )
              .toList(),
        );
      }

      if (investments.isEmpty) {
        await _migrateLegacyInvestmentsIfNeeded();
      }
    } catch (_) {
      final decoded = _decodeLegacy(
        _storageService.getValue<String>(_legacyStorageKey),
      );
      if (decoded.isEmpty) {
        investments.assignAll(_defaultInvestments());
      } else {
        investments.assignAll(decoded);
      }
    }
  }

  Future<void> addInvestment(InvestmentModel investment) async {
    final response = await _apiService.post(
      ApiConstants.investments,
      data: investment.toJson(),
    );
    final saved = InvestmentModel.fromJson(
      Map<String, dynamic>.from(response.data),
    );
    final index = investments.indexWhere((item) => item.id == saved.id);
    if (index == -1) {
      investments.add(saved);
    } else {
      investments[index] = saved;
    }
  }

  Future<void> deleteInvestment(String id) async {
    await _apiService.delete('${ApiConstants.investments}/$id');
    investments.removeWhere((item) => item.id == id);
  }

  Future<void> _migrateLegacyInvestmentsIfNeeded() async {
    final decoded = _decodeLegacy(
      _storageService.getValue<String>(_legacyStorageKey),
    );
    final items = decoded.isNotEmpty ? decoded : _defaultInvestments();
    for (final item in items) {
      await _apiService.post(ApiConstants.investments, data: item.toJson());
    }
    investments.assignAll(items);
  }

  List<InvestmentModel> _decodeLegacy(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) return <InvestmentModel>[];
    final decoded = jsonDecode(rawValue);
    if (decoded is! List) return <InvestmentModel>[];
    return decoded
        .whereType<Map>()
        .map((json) => InvestmentModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  List<InvestmentModel> _defaultInvestments() {
    return const [
      InvestmentModel(
        id: 'default-gold',
        title: 'Gram Altın',
        type: 'gold',
        principal: 25000,
        currentValue: 27800,
      ),
      InvestmentModel(
        id: 'default-deposit',
        title: 'TL Vadeli Hesap',
        type: 'deposit',
        principal: 100000,
        currentValue: 103500,
        maturityRate: 42.0,
        monthlyYield: 3500,
      ),
    ];
  }
}
