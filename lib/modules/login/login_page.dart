import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stategetx/modules/login/login_controller.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF031525), Color(0xFF0F172A), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: _GlowOrb(
                size: 180,
                color: const Color(0xFF38BDF8).withValues(alpha: 0.26),
              ),
            ),
            Positioned(
              bottom: 80,
              left: -20,
              child: _GlowOrb(
                size: 220,
                color: const Color(0xFF34D399).withValues(alpha: 0.16),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
                  return AnimatedPadding(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.fromLTRB(
                      24,
                      keyboardOpen ? 16 : 28,
                      24,
                      24 + MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - (keyboardOpen ? 12 : 32),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: keyboardOpen ? 0.72 : 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 82,
                                    height: 82,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(28),
                                      color: Colors.white.withValues(alpha: 0.10),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.14),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Kasa Akışı',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.72),
                                      letterSpacing: 1.1,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Finansını daha\nakıllı yönet',
                                    style: theme.textTheme.displaySmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      height: 1.04,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'İşlemler, kartlar, yatırımlar ve takvim akışı tek bir net finans alanında toplansın.',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.76),
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            Obx(
                              () => ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(32),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.14),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.14),
                                          blurRadius: 28,
                                          offset: const Offset(0, 18),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                controller.isRegisterMode.value
                                                    ? 'Hesap oluştur'
                                                    : 'Güvenli giriş',
                                                style: theme.textTheme.titleLarge?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.10),
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                controller.isRegisterMode.value
                                                    ? 'İlk kurulum'
                                                    : 'Devam et',
                                                style: theme.textTheme.labelMedium?.copyWith(
                                                  color: Colors.white.withValues(alpha: 0.82),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          controller.isRegisterMode.value
                                              ? 'İlk girişte güçlü şifre oluştur, sonra 6 haneli PIN ile hızlı şekilde devam et.'
                                              : 'E-posta, şifre veya Google hesabınla oturum aç.',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: Colors.white.withValues(alpha: 0.74),
                                            height: 1.42,
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        if (controller.isRegisterMode.value) ...[
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _LoginField(
                                                  controller: controller.firstNameController,
                                                  hintText: 'Ad',
                                                  textInputAction: TextInputAction.next,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: _LoginField(
                                                  controller: controller.lastNameController,
                                                  hintText: 'Soyad',
                                                  textInputAction: TextInputAction.next,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                        ],
                                        _LoginField(
                                          controller: controller.emailController,
                                          hintText: 'E-posta',
                                          keyboardType: TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          prefixIcon: Icons.alternate_email_rounded,
                                        ),
                                        const SizedBox(height: 12),
                                        _LoginField(
                                          controller: controller.passwordController,
                                          hintText: controller.isRegisterMode.value
                                              ? 'Güçlü şifre oluştur'
                                              : 'Şifre',
                                          obscureText: true,
                                          textInputAction: TextInputAction.done,
                                          prefixIcon: Icons.lock_rounded,
                                          onSubmitted: (_) => controller.submitEmailAuth(),
                                        ),
                                        if (controller.isRegisterMode.value) ...[
                                          const SizedBox(height: 10),
                                          Obx(
                                            () => _PasswordRuleCard(
                                              message: controller.passwordError.value,
                                            ),
                                          ),
                                        ],
                                        Obx(() {
                                          final message = controller.formError.value;
                                          if (message == null || message.isEmpty) {
                                            return const SizedBox.shrink();
                                          }
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 10),
                                            child: _AuthErrorCard(message: message),
                                          );
                                        }),
                                        const SizedBox(height: 18),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: controller.isLoading
                                                ? null
                                                : controller.submitEmailAuth,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: const Color(0xFF0F172A),
                                              padding: const EdgeInsets.symmetric(vertical: 18),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                            ),
                                            icon: controller.isLoading
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : const Icon(Icons.arrow_forward_rounded),
                                            label: Text(
                                              controller.isRegisterMode.value
                                                  ? 'Hesap oluştur'
                                                  : 'Giriş yap',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed: controller.isLoading
                                                ? null
                                                : controller.googleIleGirisYap,
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.white,
                                              side: BorderSide(
                                                color: Colors.white.withValues(alpha: 0.18),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                            ),
                                            icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                                            label: const Text('Google ile giriş yap'),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Center(
                                          child: TextButton(
                                            onPressed: controller.isLoading
                                                ? null
                                                : controller.toggleMode,
                                            child: Text(
                                              controller.isRegisterMode.value
                                                  ? 'Zaten hesabın var mı? Giriş yap'
                                                  : 'Hesabın yok mu? Kayıt ol',
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.88),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}

class _PasswordRuleCard extends StatelessWidget {
  const _PasswordRuleCard({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final isValid = message == null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isValid
            ? const Color(0xFF052E2B).withValues(alpha: 0.82)
            : const Color(0xFF7F1D1D).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isValid
              ? const Color(0xFF6EE7B7).withValues(alpha: 0.24)
              : const Color(0xFFFCA5A5).withValues(alpha: 0.26),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.verified_rounded : Icons.warning_amber_rounded,
            color: isValid ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message ?? 'Şifre hazır. Sonraki girişlerde 6 haneli PIN belirleyeceksin.',
              style: TextStyle(
                color: isValid ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthErrorCard extends StatelessWidget {
  const _AuthErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF7F1D1D).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFCA5A5).withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFFEE2E2),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFFEE2E2),
                fontSize: 12.8,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
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
    this.onSubmitted,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.46)),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: Colors.white.withValues(alpha: 0.70)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
        ),
      ),
    );
  }
}
