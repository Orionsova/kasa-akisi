import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stategetx/core/formatters.dart';
import 'package:stategetx/core/widgets/currency_text.dart';
import 'package:stategetx/models/app_transaction.dart';
import 'package:stategetx/models/recurring_transaction.dart';
import 'package:stategetx/modules/dashboard/dashboard_controller.dart';
import 'package:stategetx/themes/app_colors.dart';

class DashboardPage extends GetView<DashboardController> {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(
      () => RefreshIndicator(
        onRefresh: controller.refreshTransactions,
        color: colorScheme.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            Text(
              'Finans Özeti',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppFormatters.monthLabel(DateTime.now()),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _BalanceHero(
              balance: controller.balance,
              income: controller.totalIncome,
              expense: controller.totalExpense,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Gelir',
                    value: AppFormatters.currency(controller.totalIncome),
                    icon: Icons.south_west_rounded,
                    accent: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Gider',
                    value: AppFormatters.currency(controller.totalExpense),
                    icon: Icons.north_east_rounded,
                    accent: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Kart borcu',
                    value: AppFormatters.currency(controller.totalCardDebt),
                    icon: Icons.credit_card_rounded,
                    accent: const Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Yatırımlar',
                    value: AppFormatters.currency(controller.totalInvestmentValue),
                    icon: Icons.trending_up_rounded,
                    accent: const Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Yaklaşan Ödemeler',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            if (controller.upcomingRecurring.isEmpty)
              _EmptyInfoCard(
                title: 'Planlanan ödeme yok',
                subtitle: 'Takvim sekmesinden düzenli gelir veya abonelik ekleyebilirsin.',
              )
            else
              ...controller.upcomingRecurring.take(3).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RecurringPreviewTile(item: item),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'Son İşlemler',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                if (controller.isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (controller.transactions.isEmpty)
              _EmptyTransactions(theme: theme)
            else
              ...controller.transactions.map(
                (transaction) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TransactionTile(
                    transaction: transaction,
                    onDelete: () => controller.deleteTransaction(transaction.id),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({
    required this.balance,
    required this.income,
    required this.expense,
  });

  final double balance;
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final positive = balance >= 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: positive
              ? const [Color(0xFF0F766E), Color(0xFF115E59), Color(0xFF0F172A)]
              : const [Color(0xFF9F1239), Color(0xFF7F1D1D), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Toplam Bakiye',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 18),
          CurrencyText(
            AppFormatters.currency(balance),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            positive ? 'Bu ay pozitif nakit akışı var' : 'Harcamalar gelirden yüksek',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Nakit girişi',
                  value: AppFormatters.currency(income),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroMetric(
                  label: 'Nakit çıkışı',
                  value: AppFormatters.currency(expense),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.white.withValues(alpha: 0.16)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.lock_clock_rounded, color: colorScheme.onPrimary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tüm işlemler cihazda da saklanır, bağlantı yoksa kaybolmaz.',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          CurrencyText(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          CurrencyText(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecurringPreviewTile extends StatelessWidget {
  const _RecurringPreviewTile({required this.item});

  final RecurringTransaction item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = item.isIncome ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              item.isSubscription ? Icons.autorenew_rounded : Icons.schedule_rounded,
              color: accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Her ay ${item.dayOfMonth}. gün',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${item.isIncome ? '+' : '-'}${AppFormatters.currency(item.amount)}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: item.isIncome ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.onDelete,
  });

  final AppTransaction transaction;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positive = transaction.isIncome;
    final accent = positive ? AppColors.success : AppColors.error;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            positive ? Icons.add_rounded : Icons.remove_rounded,
            color: accent,
          ),
        ),
        title: Text(
          transaction.title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${transaction.category} • ${AppFormatters.shortDate(transaction.date)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (transaction.description?.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    transaction.description!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CurrencyText(
              '${positive ? '+' : '-'}${AppFormatters.currency(transaction.amount)}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  'Sil',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return _EmptyInfoCard(
      title: 'Henüz işlem yok',
      subtitle: 'Aşağıdaki artı butonundan ilk gelir veya gider kaydını ekleyebilirsin.',
    );
  }
}

class _EmptyInfoCard extends StatelessWidget {
  const _EmptyInfoCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1D4ED8), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.wallet_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
