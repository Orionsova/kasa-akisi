import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stategetx/modules/login/login_controller.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF020617), Color(0xFF0F172A), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Finansını\nkontrol altına al',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Gelir, gider ve bakiye akışını tek uygulamada net şekilde yönet.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
                const Spacer(),
                Obx(
                  () => Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.isRegisterMode.value
                              ? 'Hesap oluştur'
                              : 'Güvenli giriş',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          controller.isRegisterMode.value
                              ? 'E-posta ve şifre ile kendi hesabını oluştur.'
                              : 'E-posta, şifre veya Google hesabınla devam et.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (controller.isRegisterMode.value) ...[
                          _LoginField(
                            controller: controller.firstNameController,
                            hintText: 'Ad',
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          _LoginField(
                            controller: controller.lastNameController,
                            hintText: 'Soyad',
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                        ],
                        _LoginField(
                          controller: controller.emailController,
                          hintText: 'E-posta',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        _LoginField(
                          controller: controller.passwordController,
                          hintText: 'Şifre',
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                controller.isLoading
                                    ? null
                                    : controller.submitEmailAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0F172A),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            icon:
                                controller.isLoading
                                    ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.mail_rounded),
                            label: Text(
                              controller.isRegisterMode.value
                                  ? 'Hesap oluştur'
                                  : 'Giriş yap',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed:
                                controller.isLoading
                                    ? null
                                    : controller.googleIleGirisYap,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            icon: const Icon(Icons.login_rounded),
                            label: const Text('Google ile giriş yap'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            onPressed:
                                controller.isLoading
                                    ? null
                                    : controller.toggleMode,
                            child: Text(
                              controller.isRegisterMode.value
                                  ? 'Zaten hesabın var mı? Giriş yap'
                                  : 'Hesabın yok mu? Kayıt ol',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.86),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.48)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
        ),
      ),
    );
  }
}
