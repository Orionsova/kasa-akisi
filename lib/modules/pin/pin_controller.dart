import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stategetx/core/base_controller.dart';
import 'package:stategetx/routes/app_pages.dart';
import 'package:stategetx/services/auth_service.dart';
import 'package:stategetx/services/pin_service.dart';

class PinController extends BaseController {
  late final PinService _pinService;
  late final AuthService _authService;

  final pinController = TextEditingController();
  final confirmPinController = TextEditingController();
  final setupMode = false.obs;
  final errorText = RxnString();

  @override
  void onInit() {
    super.onInit();
    _pinService = Get.find<PinService>();
    _authService = Get.find<AuthService>();
    setupMode.value = Get.arguments == true || !_pinService.hasPin;
  }

  @override
  void onClose() {
    pinController.dispose();
    confirmPinController.dispose();
    super.onClose();
  }

  Future<void> submit() async {
    final pin = pinController.text.trim();
    errorText.value = null;

    if (!_isValidPin(pin)) {
      errorText.value = 'PIN 6 haneli olmalı.';
      return;
    }

    if (setupMode.value) {
      final confirmPin = confirmPinController.text.trim();
      if (pin != confirmPin) {
        errorText.value = 'PIN doğrulaması eşleşmiyor.';
        return;
      }

      await _pinService.savePin(pin);
      Get.offAllNamed(AppRoutes.home);
      return;
    }

    if (_pinService.verifyPin(pin)) {
      Get.offAllNamed(AppRoutes.home);
      return;
    }

    errorText.value = 'PIN hatalı.';
  }

  Future<void> useAnotherAccount() async {
    await _authService.signOut();
    Get.offAllNamed(AppRoutes.login);
  }

  bool _isValidPin(String pin) => RegExp(r'^\d{6}$').hasMatch(pin);
}
