import 'package:stategetx/core/base_controller.dart';
import 'package:flutter/material.dart';
import 'package:stategetx/routes/app_pages.dart';
import 'package:stategetx/services/auth_service.dart';
import 'package:stategetx/services/pin_service.dart';
import 'package:get/get.dart';

class LoginController extends BaseController {
  late final AuthService _authService;
  late final PinService _pinService;
  final isRegisterMode = false.obs;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final passwordError = RxnString();

  @override
  void onInit() {
    super.onInit();
    _authService = Get.find<AuthService>();
    _pinService = Get.find<PinService>();
    passwordController.addListener(_validatePasswordField);
  }

  @override
  void onClose() {
    passwordController.removeListener(_validatePasswordField);
    emailController.dispose();
    passwordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    super.onClose();
  }

  void toggleMode() {
    isRegisterMode.value = !isRegisterMode.value;
    passwordError.value = null;
  }

  Future<void> submitEmailAuth() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar('Eksik Bilgi', 'E-posta ve şifre alanlarını doldur.');
      return;
    }

    if (isRegisterMode.value && !_isStrongPassword(password)) {
      passwordError.value =
          'Şifre en az 8 karakter olmalı ve büyük/küçük harf içermeli.';
      return;
    }

    try {
      setLoading(true);
      final user =
          isRegisterMode.value
              ? await _authService.registerWithEmail(
                email: email,
                password: password,
                firstName: firstNameController.text,
                lastName: lastNameController.text,
              )
              : await _authService.signInWithEmail(
                email: email,
                password: password,
              );

      if (user != null) {
        Get.offAllNamed(_pinService.hasPin ? AppRoutes.home : AppRoutes.pin, arguments: !_pinService.hasPin);
        return;
      }

      Get.snackbar(
        'İşlem Başarısız',
        isRegisterMode.value
            ? 'Kayıt oluşturulamadı'
            : 'Giriş yapılamadı',
      );
    } catch (e) {
      Get.snackbar('İşlem Başarısız', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setLoading(false);
    }
  }

  Future<void> googleIleGirisYap() async {
    try {
      setLoading(true);
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        Get.offAllNamed(_pinService.hasPin ? AppRoutes.home : AppRoutes.pin, arguments: !_pinService.hasPin);
        return;
      }

      Get.snackbar('Giriş Hatası', 'Google ile giriş yapılamadı');
    } catch (e) {
      Get.snackbar('Giriş Hatası', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setLoading(false);
    }
  }

  void _validatePasswordField() {
    if (!isRegisterMode.value) {
      passwordError.value = null;
      return;
    }

    final password = passwordController.text;
    if (password.isEmpty) {
      passwordError.value = null;
      return;
    }

    passwordError.value = _isStrongPassword(password)
        ? null
        : 'Minimum 8 karakter, en az 1 büyük ve 1 küçük harf zorunlu.';
  }

  bool _isStrongPassword(String password) {
    final hasMinLength = password.length >= 8;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    return hasMinLength && hasUpper && hasLower;
  }
}
