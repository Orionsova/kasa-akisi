import 'dart:convert';

import 'package:get/get.dart';
import 'package:stategetx/models/investment.dart';
import 'package:stategetx/services/storage_service.dart';

class InvestmentRepository extends GetxService {
  static const String _storageKey = 'investments';

  late final StorageService _storageService;

  final RxList<InvestmentModel> investments = <InvestmentModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _storageService = Get.find<StorageService>();
    loadInvestments();
  }

  Future<void> loadInvestments() async {
    final rawValue = _storageService.getValue<String>(_storageKey);
    if (rawValue == null || rawValue.isEmpty) {
      investments.assignAll(_defaultInvestments());
      await _persist();
      return;
    }

    final decoded = jsonDecode(rawValue);
    if (decoded is! List) {
      investments.assignAll(_defaultInvestments());
      await _persist();
      return;
    }

    investments.assignAll(
      decoded
          .whereType<Map>()
          .map((json) => InvestmentModel.fromJson(Map<String, dynamic>.from(json)))
          .toList(),
    );
  }

  Future<void> addInvestment(InvestmentModel investment) async {
    investments.add(investment);
    await _persist();
  }

  Future<void> deleteInvestment(String id) async {
    investments.removeWhere((item) => item.id == id);
    await _persist();
  }

  Future<void> _persist() async {
    final encoded = jsonEncode(investments.map((item) => item.toJson()).toList());
    await _storageService.setValue<String>(_storageKey, encoded);
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
