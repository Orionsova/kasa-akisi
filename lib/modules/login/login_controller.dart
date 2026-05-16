import 'package:stategetx/core/base_controller.dart';
import 'package:flutter/material.dart';
import 'package:stategetx/routes/app_pages.dart';
import 'package:stategetx/services/auth_service.dart';
import 'package:get/get.dart';

class LoginController extends BaseController {
  late final AuthService _authService;
  final isRegisterMode = false.obs;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _authService = Get.find<AuthService>();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    super.onClose();
  }

  void toggleMode() {
    isRegisterMode.value = !isRegisterMode.value;
  }

  Future<void> submitEmailAuth() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar('Eksik Bilgi', 'E-posta ve şifre alanlarını doldur.');
      return;
    }

    if (isRegisterMode.value && password.length < 6) {
      Get.snackbar('Şifre Kısa', 'Şifre en az 6 karakter olmalı.');
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
        Get.offAllNamed(AppRoutes.home);
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
        Get.offAllNamed(AppRoutes.home);
        return;
      }

      Get.snackbar('Giriş Hatası', 'Google ile giriş yapılamadı');
    } catch (e) {
      Get.snackbar('Giriş Hatası', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setLoading(false);
    }
  }
}
