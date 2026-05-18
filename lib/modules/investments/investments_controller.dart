import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stategetx/core/base_controller.dart';
import 'package:stategetx/core/formatters.dart';
import 'package:stategetx/models/investment.dart';
import 'package:stategetx/repositoryies/investment_repository.dart';
import 'package:stategetx/services/api_service.dart';

class InvestmentsController extends BaseController {
  final InvestmentRepository _investmentRepository =
      Get.find<InvestmentRepository>();
  final ApiService _apiService = Get.find<ApiService>();

  final titleController = TextEditingController();
  final principalController = TextEditingController();
  final currentValueController = TextEditingController();
  final maturityRateController = TextEditingController();
  final monthlyYieldController = TextEditingController();
  final termDaysController = TextEditingController();
  final symbolController = TextEditingController();
  final noteController = TextEditingController();

  final selectedType = 'gold'.obs;
  final marketLoading = false.obs;
  final marketError = RxnString();
  final marketLastUpdated = Rxn<DateTime>();
  final marketItems = <MarketTicker>[].obs;

  RxList<InvestmentModel> get investments => _investmentRepository.investments;

  @override
  void onInit() {
    super.onInit();
    ever(selectedType, (_) => _recalculateDepositProjection());
    maturityRateController.addListener(_recalculateDepositProjection);
    principalController.addListener(_recalculateDepositProjection);
    termDaysController.addListener(_recalculateDepositProjection);
    loadMarketData();
  }

  @override
  void onClose() {
    titleController.dispose();
    principalController.dispose();
    currentValueController.dispose();
    maturityRateController.dispose();
    monthlyYieldController.dispose();
    termDaysController.dispose();
    symbolController.dispose();
    noteController.dispose();
    super.onClose();
  }

  double get totalValue =>
      investments.fold(0, (sum, item) => sum + item.currentValue);

  double get totalPrincipal =>
      investments.fold(0, (sum, item) => sum + item.principal);

  double get totalProfitLoss => totalValue - totalPrincipal;

  Future<void> loadInvestments() => _investmentRepository.loadInvestments();

  Future<void> loadMarketData() async {
    if (marketLoading.value) return;

    marketLoading.value = true;
    marketError.value = null;

    try {
      final response = await _apiService.get(ApiConstants.marketOverview);
      final data = Map<String, dynamic>.from(response.data as Map);
      final items = (data['items'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((json) => MarketTicker.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      if (items.isEmpty) {
        throw Exception('Piyasa verisi boş geldi');
      }

      marketItems.assignAll(items);
      final updatedAt = data['updatedAt']?.toString();
      marketLastUpdated.value = updatedAt == null
          ? DateTime.now()
          : DateTime.tryParse(updatedAt) ?? DateTime.now();
    } catch (_) {
      marketError.value =
          'Piyasa verisi şu an alınamadı. Backend piyasa servisini kontrol et.';
    } finally {
      marketLoading.value = false;
    }
  }

  Future<void> addInvestment() async {
    final principal = AppFormatters.parseCurrencyInput(principalController.text);
    double? currentValue = double.tryParse(
      currentValueController.text.replaceAll('.', '').replaceAll(',', '.'),
    );
    final maturityRate = maturityRateController.text.trim().isEmpty
        ? null
        : double.tryParse(maturityRateController.text.replaceAll(',', '.'));
    final monthlyYield = monthlyYieldController.text.trim().isEmpty
        ? null
        : double.tryParse(monthlyYieldController.text.replaceAll(',', '.'));
    final termDays = termDaysController.text.trim().isEmpty
        ? null
        : int.tryParse(termDaysController.text.trim());

    if (titleController.text.trim().isEmpty || principal == null) {
      Get.snackbar('Hata', 'Yatırım bilgilerini eksiksiz doldurun');
      return;
    }

    if (selectedType.value == 'deposit') {
      if (maturityRate == null || termDays == null) {
        Get.snackbar('Hata', 'Vadeli hesap için gün ve faiz oranı girin');
        return;
      }
      currentValue ??= principal;
    }

    if (currentValue == null) {
      Get.snackbar('Hata', 'Güncel değer bilgisi eksik');
      return;
    }

    final investment = InvestmentModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      type: selectedType.value,
      principal: principal,
      currentValue: currentValue,
      maturityRate: maturityRate,
      monthlyYield: monthlyYield,
      termDays: termDays,
      openedAt: selectedType.value == 'deposit' ? DateTime.now() : null,
      symbol: symbolController.text.trim().isEmpty
          ? null
          : symbolController.text.trim(),
      note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
    );

    await _investmentRepository.addInvestment(investment);
    clearForm();
    Get.snackbar('Başarılı', 'Yatırım eklendi');
  }

  Future<void> deleteInvestment(String id) async {
    await _investmentRepository.deleteInvestment(id);
    Get.snackbar('Silindi', 'Yatırım kaldırıldı');
  }

  Future<void> updateInvestmentCurrentValue(
    InvestmentModel investment,
    double currentValue,
  ) async {
    await _investmentRepository.addInvestment(
      InvestmentModel(
        id: investment.id,
        title: investment.title,
        type: investment.type,
        principal: investment.principal,
        currentValue: currentValue,
        maturityRate: investment.maturityRate,
        monthlyYield: investment.monthlyYield,
        termDays: investment.termDays,
        openedAt: investment.openedAt,
        symbol: investment.symbol,
        note: investment.note,
      ),
    );
    Get.snackbar('Güncellendi', 'Yatırım değeri güncellendi');
  }

  void clearForm() {
    titleController.clear();
    principalController.clear();
    currentValueController.clear();
    maturityRateController.clear();
    monthlyYieldController.clear();
    termDaysController.clear();
    symbolController.clear();
    noteController.clear();
    selectedType.value = 'gold';
  }

  double? get projectedDepositYield {
    final principal = AppFormatters.parseCurrencyInput(principalController.text);
    final annualRate = double.tryParse(
      maturityRateController.text.replaceAll(',', '.'),
    );
    final termDays = int.tryParse(termDaysController.text.trim());
    if (principal == null || annualRate == null || termDays == null) {
      return null;
    }

    return _calculateDepositYield(
      principal: principal,
      annualRate: annualRate,
      termDays: termDays,
    );
  }

  double? get projectedDepositCurrentValue {
    final principal = AppFormatters.parseCurrencyInput(principalController.text);
    final annualRate = double.tryParse(
      maturityRateController.text.replaceAll(',', '.'),
    );
    final termDays = int.tryParse(termDaysController.text.trim());
    if (principal == null || annualRate == null || termDays == null) {
      return null;
    }

    return _calculateDepositCurrentValue(
      principal: principal,
      annualRate: annualRate,
      termDays: termDays,
    );
  }

  void applyMarketSymbol(MarketTicker ticker) {
    selectedType.value = ticker.code == 'XAU' ? 'gold' : 'fx';
    titleController.text = ticker.title;
    symbolController.text = ticker.code;
  }

  void _recalculateDepositProjection() {
    if (selectedType.value != 'deposit') {
      return;
    }

    final projectedValue = projectedDepositCurrentValue;
    final projectedYield = projectedDepositYield;
    if (currentValueController.text.trim().isEmpty ||
        AppFormatters.parseCurrencyInput(currentValueController.text) == null) {
      currentValueController.text = principalController.text;
    }
    monthlyYieldController.text = projectedYield == null
        ? ''
        : AppFormatters.amountInput(projectedYield);
    if (projectedValue != null) {
      // Keeps derived value available to the UI without forcing it into the live portfolio.
    }
  }

  double _calculateDepositYield({
    required double principal,
    required double annualRate,
    required int termDays,
  }) {
    return principal * (annualRate / 100) * (termDays / 365);
  }

  double _calculateDepositCurrentValue({
    required double principal,
    required double annualRate,
    required int termDays,
  }) {
    return principal +
        _calculateDepositYield(
          principal: principal,
          annualRate: annualRate,
          termDays: termDays,
        );
  }
}

class MarketTicker {
  const MarketTicker({
    required this.code,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
  });

  final String code;
  final String title;
  final double value;
  final String subtitle;
  final Color accent;

  factory MarketTicker.fromJson(Map<String, dynamic> json) {
    return MarketTicker(
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      subtitle: json['subtitle']?.toString() ?? '',
      accent: _parseHexColor(json['accentHex']?.toString()) ??
          const Color(0xFF1D4ED8),
    );
  }

  static Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final normalized = hex.replaceFirst('#', '');
    if (normalized.length != 6) return null;
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }
}
