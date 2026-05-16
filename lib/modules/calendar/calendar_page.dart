import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:stategetx/core/formatters.dart';
import 'package:stategetx/core/widgets/currency_text.dart';
import 'package:stategetx/models/recurring_transaction.dart';
import 'package:stategetx/modules/calendar/calendar_controller.dart';
import 'package:stategetx/themes/app_colors.dart';

class CalendarPage extends GetView<CalendarController> {
  const CalendarPage({super.key});

  void _showRecurringDialog(BuildContext context) {
    controller.clearRecurringForm();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Düzenli kayıt ekle',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'expense', label: Text('Gider')),
                      ButtonSegment(value: 'income', label: Text('Gelir')),
                    ],
                    selected: {controller.recurringType.value},
                    onSelectionChanged: (selection) {
                      controller.recurringType.value = selection.first;
                    },
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Abonelik olarak işaretle'),
                    subtitle: const Text('Netflix, Spotify, aidat gibi'),
                    value: controller.isSubscription.value,
                    onChanged: (value) => controller.isSubscription.value = value,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller.titleController,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.sentences,
                    autocorrect: true,
                    enableSuggestions: true,
                    decoration: const InputDecoration(
                      labelText: 'Başlık',
                      hintText: 'Örn. Kira, Maaş, Spotify',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
                    ],
                    decoration: const InputDecoration(labelText: 'Tutar'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.dayController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Her ayın kaçında',
                      hintText: '1 - 31',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.noteController,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.sentences,
                    autocorrect: true,
                    enableSuggestions: true,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Not',
                      hintText: 'İsteğe bağlı açıklama',
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await controller.createRecurringTransaction();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Kaydet'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(
      () => RefreshIndicator(
        onRefresh: controller.refreshAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            Row(
              children: [
                Text(
                  'Takvim',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: controller.goToPreviousMonth,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text(
                  AppFormatters.monthLabel(controller.selectedMonth.value),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: controller.goToNextMonth,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Yaklaşan nakit akışı',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _FlowMetric(
                          label: 'Düzenli gelir',
                          value: AppFormatters.currency(
                            controller.totalRecurringIncomeForMonth(
                              controller.selectedMonth.value,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FlowMetric(
                          label: 'Düzenli gider',
                          value: AppFormatters.currency(
                            controller.totalRecurringExpenseForMonth(
                              controller.selectedMonth.value,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => _showRecurringDialog(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Düzenli kayıt ekle'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _MonthGrid(controller: controller),
            const SizedBox(height: 24),
            Text(
              'Seçili gün',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            _SelectedDayDetails(controller: controller),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'Yaklaşan düzenli ödemeler',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showRecurringDialog(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Ekle'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (controller.upcomingRecurring.isEmpty)
              _CalendarEmptyCard(
                title: 'Henüz düzenli kayıt yok',
                subtitle: 'Abonelik, maaş veya kira gibi kayıtları buradan ekleyebilirsin.',
              )
            else
              ...controller.upcomingRecurring.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RecurringTile(
                    entry: entry,
                    onDelete: () => controller.deleteRecurringTransaction(entry.id),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.controller});

  final CalendarController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = controller.visibleMonthDays;
    const weekDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: weekDays
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final date = days[index];
              if (date == null) {
                return const SizedBox.shrink();
              }
              final selected = controller.selectedDate.value.year == date.year &&
                  controller.selectedDate.value.month == date.month &&
                  controller.selectedDate.value.day == date.day;
              final hasEntry = controller.hasEntriesOn(date);

              return InkWell(
                onTap: () => controller.selectDate(date),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : hasEntry
                            ? AppColors.accent.withValues(alpha: 0.12)
                            : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: selected
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (hasEntry)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: selected ? Colors.white : AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SelectedDayDetails extends StatelessWidget {
  const _SelectedDayDetails({required this.controller});

  final CalendarController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedDate = controller.selectedDate.value;
    final transactions = controller.transactionsForDate(selectedDate);
    final recurring = controller.recurringForDate(selectedDate);
    final cardStatements = controller.cardStatementsForDate(selectedDate);

    if (transactions.isEmpty && recurring.isEmpty && cardStatements.isEmpty) {
      return _CalendarEmptyCard(
        title: AppFormatters.dayMonthLabel(selectedDate),
        subtitle: 'Bu gün için planlanmış gelir veya gider bulunmuyor.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppFormatters.dayMonthLabel(selectedDate),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (transactions.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Gerçekleşen işlemler'),
            const SizedBox(height: 8),
            ...transactions.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.title),
                subtitle: Text(item.category),
                trailing: Text(
                  '${item.isIncome ? '+' : '-'}${AppFormatters.currency(item.amount)}',
                  style: TextStyle(
                    color: item.isIncome ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
          if (recurring.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Beklenen düzenli kayıtlar'),
            const SizedBox(height: 8),
            ...recurring.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.title),
                subtitle: Text(item.isSubscription ? 'Abonelik' : item.category),
                trailing: Text(
                  '${item.isIncome ? '+' : '-'}${AppFormatters.currency(item.amount)}',
                  style: TextStyle(
                    color: item.isIncome ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
          if (cardStatements.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Kart hesap kesimi'),
            const SizedBox(height: 8),
            ...cardStatements.map(
              (card) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(card.name),
                subtitle: Text(
                  'Bu ay borcu • Gelecek dönem: ${AppFormatters.currency(card.nextPeriodDebt)}',
                ),
                trailing: Text(
                  AppFormatters.currency(card.currentStatementDebt),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecurringTile extends StatelessWidget {
  const _RecurringTile({required this.entry, required this.onDelete});

  final RecurringTransaction entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = entry.isIncome ? AppColors.success : AppColors.error;

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
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              entry.isSubscription ? Icons.sync_rounded : Icons.calendar_month_rounded,
              color: accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Her ay ${entry.dayOfMonth}. gün • ${entry.isSubscription ? 'Abonelik' : entry.category}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.isIncome ? '+' : '-'}${AppFormatters.currency(entry.amount)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarEmptyCard extends StatelessWidget {
  const _CalendarEmptyCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowMetric extends StatelessWidget {
  const _FlowMetric({required this.label, required this.value});

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
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
