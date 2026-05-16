import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stategetx/modules/calendar/calendar_page.dart';
import 'package:stategetx/modules/credit_cards/credit_cards_page.dart';
import 'package:stategetx/modules/dashboard/dashboard_page.dart';
import 'package:stategetx/modules/home/home_controller.dart';
import 'package:stategetx/modules/investments/investments_page.dart';
import 'package:stategetx/modules/profile/profile_page.dart';
import 'package:stategetx/services/privacy_service.dart';
import 'package:stategetx/themes/app_colors.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final privacyService = Get.find<PrivacyService>();

    return Obx(() {
      privacyService.hideAmounts.value;
      final pages = [
        const DashboardPage(),
        const CalendarPage(),
        const CreditCardsPage(),
        const InvestmentsPage(),
        const ProfilePage(),
      ];

      return Scaffold(
      extendBody: true,
      appBar: AppBar(
        toolbarHeight: 74,
        titleSpacing: 20,
        title: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.titles[controller.currentIndex.value],
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              Text(
                controller.subtitles[controller.currentIndex.value],
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.82),
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: privacyService.toggleAmountVisibility,
            icon: Icon(
              privacyService.hideAmounts.value
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
            ),
            tooltip: privacyService.hideAmounts.value
                ? 'Tutarları göster'
                : 'Tutarları gizle',
          ),
          const SizedBox(width: 8),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1D4ED8), Color(0xFF0F766E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor,
              AppColors.primary.withValues(alpha: 0.04),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Obx(() => IndexedStack(
              index: controller.currentIndex.value,
              children: pages,
            )),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.goToTransaction,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 26),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Obx(
        () => NavigationBar(
          selectedIndex: controller.currentIndex.value,
          onDestinationSelected: controller.changePage,
          backgroundColor: theme.colorScheme.surface,
          indicatorColor: AppColors.accent.withValues(alpha: 0.14),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Özet',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_rounded),
              label: 'Takvim',
            ),
            NavigationDestination(
              icon: Icon(Icons.credit_card_rounded),
              label: 'Kartlar',
            ),
            NavigationDestination(
              icon: Icon(Icons.trending_up_rounded),
              label: 'Yatırım',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
      );
    });
  }
}
