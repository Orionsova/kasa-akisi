import 'dart:convert';

import 'package:get/get.dart';
import 'package:stategetx/models/app_user.dart';
import 'package:stategetx/models/investment.dart';
import 'package:stategetx/services/api_service.dart';
import 'package:stategetx/services/auth_service.dart';
import 'package:stategetx/services/storage_service.dart';

class InvestmentRepository extends GetxService {
  static const String _legacyStorageKey = 'investments';
  static const String _legacyStorageOwnerKey = 'investments_owner';

  late final ApiService _apiService;
  late final StorageService _storageService;
  late final AuthService _authService;

  final RxList<InvestmentModel> investments = <InvestmentModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _storageService = Get.find<StorageService>();
    _authService = Get.find<AuthService>();
    ever<AppUser?>(_authService.currentUser, (_) => loadInvestments());
    loadInvestments();
  }

  Future<void> loadInvestments() async {
    if (_authService.currentUser.value == null) {
      investments.clear();
      return;
    }

    try {
      final response = await _apiService.get(ApiConstants.investments);
      final decoded = response.data;
      if (decoded is List) {
        investments.assignAll(
          decoded
              .whereType<Map>()
              .map(
                (json) =>
                    InvestmentModel.fromJson(Map<String, dynamic>.from(json)),
              )
              .toList(),
        );
        await _persist();
        return;
      }
    } catch (_) {
      // Fallback below.
    }

    await _migrateLegacyInvestmentsIfNeeded();
    investments.assignAll(_decode(_storageService.getValue<String>(_scopedStorageKey())));
  }

  Future<void> addInvestment(InvestmentModel investment) async {
    try {
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
      await _persist();
      return;
    } catch (_) {
      final index = investments.indexWhere((item) => item.id == investment.id);
      if (index == -1) {
        investments.add(investment);
      } else {
        investments[index] = investment;
      }
      await _persist();
    }
  }

  Future<void> deleteInvestment(String id) async {
    try {
      await _apiService.delete('${ApiConstants.investments}/$id');
    } catch (_) {
      // Keep local state consistent.
    }

    investments.removeWhere((item) => item.id == id);
    await _persist();
  }

  Future<void> _persist() async {
    await _storageService.setValue<String>(
      _scopedStorageKey(),
      jsonEncode(investments.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> _migrateLegacyInvestmentsIfNeeded() async {
    if (_storageService.hasKey(_scopedStorageKey())) return;

    final ownerKey = _currentUserStorageKey();
    final legacyOwner = _storageService.getValue<String>(_legacyStorageOwnerKey);
    if (legacyOwner != null && legacyOwner != ownerKey) {
      return;
    }

    final decoded = _decode(_storageService.getValue<String>(_legacyStorageKey));
    if (decoded.isEmpty) return;

    for (final investment in decoded) {
      try {
        await _apiService.post(
          ApiConstants.investments,
          data: investment.toJson(),
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

  String _scopedStorageKey() => 'investments_${_currentUserStorageKey()}';

  String _currentUserStorageKey() {
    final user = _authService.currentUser.value;
    final userId = user?.id?.trim();
    final email = user?.email?.trim().toLowerCase();
    final base = userId != null && userId.isNotEmpty
        ? userId
        : (email != null && email.isNotEmpty ? email : 'anonymous');
    return base.replaceAll(RegExp(r'[^a-zA-Z0-9_\-@.]'), '_');
  }

  List<InvestmentModel> _decode(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) return <InvestmentModel>[];
    final decoded = jsonDecode(rawValue);
    if (decoded is! List) return <InvestmentModel>[];
    return decoded
        .whereType<Map>()
        .map((json) => InvestmentModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }
}
