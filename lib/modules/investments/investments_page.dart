import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:stategetx/core/formatters.dart';
import 'package:stategetx/core/input_formatters.dart';
import 'package:stategetx/core/widgets/currency_text.dart';
import 'package:stategetx/models/investment.dart';
import 'package:stategetx/modules/investments/investments_controller.dart';
import 'package:stategetx/themes/app_colors.dart';

class InvestmentsPage extends GetView<InvestmentsController> {
  const InvestmentsPage({super.key});

  void _showAddInvestmentDialog(BuildContext context) {
    controller.clearForm();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
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
                    'Yatırım ekle',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'gold', label: Text('Altın')),
                      ButtonSegment(value: 'fx', label: Text('Döviz')),
                      ButtonSegment(value: 'deposit', label: Text('TL Vadeli')),
                    ],
                    selected: {controller.selectedType.value},
                    onSelectionChanged: (selection) {
                      controller.selectedType.value = selection.first;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller.titleController,
                    decoration: InputDecoration(
                      labelText: 'Yatırım adı',
                      hintText: controller.selectedType.value == 'deposit'
                          ? 'Örn. 32 Günlük Vadeli'
                          : 'Örn. Gram Altın, USD, EUR',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (controller.selectedType.value == 'fx' ||
                      controller.selectedType.value == 'gold')
                    TextField(
                      controller: controller.symbolController,
                      decoration: InputDecoration(
                        labelText: 'Sembol',
                        hintText: controller.selectedType.value == 'gold'
                            ? 'Örn. XAU'
                            : 'Örn. USD, EUR',
                      ),
                    ),
                  if (controller.selectedType.value == 'fx' ||
                      controller.selectedType.value == 'gold')
                    const SizedBox(height: 12),
                  TextField(
                    controller: controller.principalController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [TurkishGroupedNumberInputFormatter()],
                    decoration: const InputDecoration(labelText: 'Anapara'),
                  ),
                  if (controller.selectedType.value == 'deposit') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller.termDaysController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Kaç gün',
                        hintText: 'Örn. 32',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller.maturityRateController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*[.,]?\d{0,2}'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Yıllık faiz oranı (%)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DepositProjectionCard(controller: controller),
                  ] else ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller.currentValueController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [TurkishGroupedNumberInputFormatter()],
                      decoration: const InputDecoration(labelText: 'Güncel değer'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Not',
                      hintText: 'İsteğe bağlı',
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await controller.addInvestment();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Yatırımı kaydet'),
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
      () => ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          Row(
            children: [
              Text(
                'Yatırımlar',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showAddInvestmentDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Yeni yatırım'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF111827), Color(0xFF0F766E), Color(0xFFB45309)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Toplam portföy', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                CurrencyText(
                  AppFormatters.currency(controller.totalValue),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _InvestmentMetric(
                        label: 'Anapara',
                        value: AppFormatters.currency(controller.totalPrincipal),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InvestmentMetric(
                        label: 'Kâr / Zarar',
                        value: AppFormatters.currency(controller.totalProfitLoss),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _MarketWatchCard(controller: controller),
          const SizedBox(height: 20),
          if (controller.investments.isEmpty)
            _EmptyInvestments(onAdd: () => _showAddInvestmentDialog(context))
          else
            ...controller.investments.map(
              (investment) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _InvestmentTile(
                  investment: investment,
                  onDelete: () => controller.deleteInvestment(investment.id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MarketWatchCard extends StatelessWidget {
  const _MarketWatchCard({required this.controller});

  final InvestmentsController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Piyasa Takibi',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: controller.marketLoading.value
                    ? null
                    : controller.loadMarketData,
                icon: controller.marketLoading.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            controller.marketLastUpdated.value == null
                ? 'Dolar, euro ve gram altın için ücretsiz canlı gösterim.'
                : 'Son güncelleme ${AppFormatters.shortDate(controller.marketLastUpdated.value!)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (controller.marketError.value != null) ...[
            const SizedBox(height: 12),
            Text(
              controller.marketError.value!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (controller.marketItems.isEmpty && !controller.marketLoading.value)
            Text(
              'Piyasa verisi henüz yüklenemedi.',
              style: theme.textTheme.bodyMedium,
            )
          else
            ...controller.marketItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
              child: _MarketTickerTile(
                  item: item,
                  onUse: () => controller.applyMarketSymbol(item),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MarketTickerTile extends StatelessWidget {
  const _MarketTickerTile({
    required this.item,
    required this.onUse,
  });

  final MarketTicker item;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: item.accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              item.code == 'XAU'
                  ? Icons.workspace_premium_rounded
                  : Icons.currency_exchange_rounded,
              color: item.accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
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
              CurrencyText(
                AppFormatters.currency(item.value),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: item.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onUse,
                child: const Text('Kullan'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DepositProjectionCard extends StatelessWidget {
  const _DepositProjectionCard({required this.controller});

  final InvestmentsController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final projectedYield = controller.projectedDepositYield;
    final projectedValue = controller.projectedDepositCurrentValue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F766E).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF0F766E).withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vadeli Hesap Tahmini',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Basit brüt faiz hesabı kullanılır: anapara x faiz x gün / 365',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InvestmentInfo(
                  label: 'Tahmini kazanç',
                  value: projectedYield == null
                      ? '-'
                      : AppFormatters.currency(projectedYield),
                  valueColor: AppColors.success,
                ),
              ),
              Expanded(
                child: _InvestmentInfo(
                  label: 'Tahmini vade sonu',
                  value: projectedValue == null
                      ? '-'
                      : AppFormatters.currency(projectedValue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bu tutar tahminidir. Portföyde gerçek güncel değer ayrı tutulur; vade sonunda kullanıcı tarafından güncellenebilir.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvestmentTile extends StatelessWidget {
  const _InvestmentTile({
    required this.investment,
    required this.onDelete,
  });

  final InvestmentModel investment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positive = investment.profitLoss >= 0;
    final openedAt = investment.openedAt;
    final closingDate = openedAt != null && investment.termDays != null
        ? openedAt.add(Duration(days: investment.termDays!))
        : null;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  investment.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: investment.type == 'deposit'
                    ? () => _showUpdateValueDialog(context)
                    : null,
                icon: Icon(
                  Icons.edit_outlined,
                  color: investment.type == 'deposit'
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
              ),
            ],
          ),
          Text(
            _typeLabel(investment.type, investment.symbol),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InvestmentInfo(
                  label: 'Anapara',
                  value: AppFormatters.currency(investment.principal),
                ),
              ),
              Expanded(
                child: _InvestmentInfo(
                  label: 'Güncel',
                  value: AppFormatters.currency(investment.currentValue),
                ),
              ),
              Expanded(
                child: _InvestmentInfo(
                  label: 'Kâr / Zarar',
                  value: AppFormatters.currency(investment.profitLoss),
                  valueColor: positive ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
          if (investment.type == 'deposit') ...[
            const SizedBox(height: 12),
            Text(
              'Açılış: ${openedAt == null ? '-' : AppFormatters.shortDate(openedAt)} • Kapanış: ${closingDate == null ? '-' : AppFormatters.shortDate(closingDate)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: Color(0xFF0F766E),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Faiz: ${investment.maturityRate?.toStringAsFixed(2) ?? '-'}% • Süre: ${investment.termDays ?? '-'} gün • Tahmini vade sonu: ${investment.monthlyYield == null ? '-' : AppFormatters.currency(investment.principal + investment.monthlyYield!)}. Bu alan tahminidir.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (investment.note?.isNotEmpty ?? false) ...[
            const SizedBox(height: 10),
            Text(
              investment.note!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _typeLabel(String type, String? symbol) {
    switch (type) {
      case 'gold':
        return symbol == null || symbol.isEmpty ? 'Altın' : 'Altın • $symbol';
      case 'fx':
        return symbol == null || symbol.isEmpty ? 'Döviz' : 'Döviz • $symbol';
      case 'deposit':
        return 'TL Vadeli';
      default:
        return type;
    }
  }

  void _showUpdateValueDialog(BuildContext context) {
    final valueController = TextEditingController(
      text: AppFormatters.amountInput(investment.currentValue),
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Güncel tutarı güncelle'),
        content: TextField(
          controller: valueController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [TurkishGroupedNumberInputFormatter()],
          decoration: const InputDecoration(
            labelText: 'Gerçek güncel değer',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final parsed = AppFormatters.parseCurrencyInput(valueController.text);
              if (parsed == null) {
                return;
              }
              await Get.find<InvestmentsController>().updateInvestmentCurrentValue(
                investment,
                parsed,
              );
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }
}

class _InvestmentInfo extends StatelessWidget {
  const _InvestmentInfo({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        CurrencyText(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _InvestmentMetric extends StatelessWidget {
  const _InvestmentMetric({required this.label, required this.value});

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
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _EmptyInvestments extends StatelessWidget {
  const _EmptyInvestments({required this.onAdd});

  final VoidCallback onAdd;

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
          const Icon(Icons.trending_up_rounded, size: 42),
          const SizedBox(height: 14),
          Text(
            'Henüz yatırım eklenmemiş',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Döviz, altın veya vadeli hesaplarını burada takip edebilirsin.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('İlk yatırımı ekle'),
          ),
        ],
      ),
    );
  }
}
