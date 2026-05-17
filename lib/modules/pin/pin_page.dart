import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stategetx/modules/pin/pin_controller.dart';

class PinPage extends GetView<PinController> {
  const PinPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF031525), Color(0xFF0F172A), Color(0xFF0F766E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Obx(
                  () => Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.lock_person_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          controller.setupMode.value
                              ? '6 haneli PIN oluştur'
                              : 'PIN ile devam et',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          controller.setupMode.value
                              ? 'Şifreyi ilk güvenlik adımı olarak kullandın. Sonraki girişlerde bu 6 haneli PIN ile devam edebilirsin.'
                              : 'Hesabına devam etmek için 6 haneli PIN’ini gir.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.76),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _PinField(
                          controller: controller.pinController,
                          hintText: 'PIN',
                          onSubmitted: (_) => controller.submit(),
                        ),
                        if (controller.setupMode.value) ...[
                          const SizedBox(height: 12),
                          _PinField(
                            controller: controller.confirmPinController,
                            hintText: 'PIN tekrar',
                            onSubmitted: (_) => controller.submit(),
                          ),
                        ],
                        if (controller.errorText.value != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7F1D1D).withValues(
                                alpha: 0.72,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFFCA5A5).withValues(
                                  alpha: 0.30,
                                ),
                              ),
                            ),
                            child: Text(
                              controller.errorText.value!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFFFEE2E2),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: controller.submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0F172A),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            child: Text(
                              controller.setupMode.value
                                  ? 'PIN’i kaydet'
                                  : 'Devam et',
                            ),
                          ),
                        ),
                        if (!controller.setupMode.value) ...[
                          const SizedBox(height: 10),
                          Center(
                            child: TextButton(
                              onPressed: controller.useAnotherAccount,
                              child: Text(
                                'Başka hesapla giriş yap',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.84),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  const _PinField({
    required this.controller,
    required this.hintText,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      obscureText: true,
      maxLength: 6,
      onSubmitted: onSubmitted,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        letterSpacing: 10,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.42)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
        ),
      ),
    );
  }
}
