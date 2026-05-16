import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stategetx/core/base_controller.dart';
import 'package:stategetx/models/investment.dart';
import 'package:stategetx/repositoryies/investment_repository.dart';

class InvestmentsController extends BaseController {
  final InvestmentRepository _investmentRepository =
      Get.find<InvestmentRepository>();

  final titleController = TextEditingController();
  final principalController = TextEditingController();
  final currentValueController = TextEditingController();
  final maturityRateController = TextEditingController();
  final monthlyYieldController = TextEditingController();
  final symbolController = TextEditingController();
  final noteController = TextEditingController();

  final selectedType = 'gold'.obs;

  RxList<InvestmentModel> get investments => _investmentRepository.investments;

  @override
  void onClose() {
    titleController.dispose();
    principalController.dispose();
    currentValueController.dispose();
    maturityRateController.dispose();
    monthlyYieldController.dispose();
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

  Future<void> addInvestment() async {
    final principal = double.tryParse(principalController.text.replaceAll(',', '.'));
    final currentValue = double.tryParse(
      currentValueController.text.replaceAll(',', '.'),
    );
    final maturityRate = maturityRateController.text.trim().isEmpty
        ? null
        : double.tryParse(maturityRateController.text.replaceAll(',', '.'));
    final monthlyYield = monthlyYieldController.text.trim().isEmpty
        ? null
        : double.tryParse(monthlyYieldController.text.replaceAll(',', '.'));

    if (titleController.text.trim().isEmpty ||
        principal == null ||
        currentValue == null) {
      Get.snackbar('Hata', 'Yatırım bilgilerini eksiksiz doldurun');
      return;
    }

    if (selectedType.value == 'deposit' &&
        (maturityRate == null || monthlyYield == null)) {
      Get.snackbar('Hata', 'Vadeli hesap için oran ve aylık kazanç girin');
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

  void clearForm() {
    titleController.clear();
    principalController.clear();
    currentValueController.clear();
    maturityRateController.clear();
    monthlyYieldController.clear();
    symbolController.clear();
    noteController.clear();
    selectedType.value = 'gold';
  }
}
