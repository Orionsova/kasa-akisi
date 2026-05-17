import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stategetx/modules/profile/progile_controller.dart';
import 'package:stategetx/modules/profile/widgets/info_card.dart';

class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final user = controller.user.value;
      final photoUrl = user?.profilePhoto ?? '';

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF111827), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    backgroundImage:
                        photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child:
                        photoUrl.isEmpty
                            ? const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 36,
                            )
                            : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim().isEmpty
                        ? 'Profil'
                        : '${user?.firstName ?? ''} ${user?.lastName ?? ''}'
                            .trim(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user?.email ?? 'Hesap bilgisi bulunamadı',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            InfoCard(title: 'Ad', value: user?.firstName ?? '-'),
            InfoCard(title: 'Soyad', value: user?.lastName ?? '-'),
            InfoCard(title: 'E-posta', value: user?.email ?? '-'),
            const SizedBox(height: 8),
            SettingsCard(controller: controller),
            const SizedBox(height: 12),
            LogoutCard(controller: controller),
          ],
        ),
      );
    });
  }
}

class SettingsCard extends StatelessWidget {
  const SettingsCard({required this.controller, super.key});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Obx(
          () {
            final isDark = controller.themeService.isDarkMode;
            final hideAmounts = controller.privacyService.hideAmounts.value;

            return Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tema Modu',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isDark ? 'Koyu tema aktif' : 'Açık tema aktif',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isDark,
                      onChanged: (_) => controller.themeService.toggleTheme(),
                      activeThumbColor: theme.colorScheme.primary,
                      activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.28),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        hideAmounts
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tutar Gizliliği',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hideAmounts
                                ? 'Tüm para tutarları gizleniyor'
                                : 'Para tutarları görünür',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: hideAmounts,
                      onChanged: (_) => controller.privacyService.toggleAmountVisibility(),
                      activeThumbColor: theme.colorScheme.primary,
                      activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.28),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class LogoutCard extends StatelessWidget {
  const LogoutCard({required this.controller, super.key});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Çıkış Yap',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hesabından güvenli şekilde çıkış yap',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: controller.signOut,
              child: const Text('Çıkış yap'),
            ),
          ],
        ),
      ),
    );
  }
}
