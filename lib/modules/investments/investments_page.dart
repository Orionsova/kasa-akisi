import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:stategetx/core/formatters.dart';
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
                      ButtonSegment(value: 'stock', label: Text('Borsa')),
                    ],
                    selected: {controller.selectedType.value},
                    onSelectionChanged: (selection) {
                      controller.selectedType.value = selection.first;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller.titleController,
                    decoration: const InputDecoration(
                      labelText: 'Yatırım adı',
                      hintText: 'Örn. Gram Altın, USD, ASELS',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (controller.selectedType.value == 'stock' ||
                      controller.selectedType.value == 'fx')
                    TextField(
                      controller: controller.symbolController,
                      decoration: const InputDecoration(
                        labelText: 'Sembol',
                        hintText: 'Örn. ASELS, USDTRY',
                      ),
                    ),
                  if (controller.selectedType.value == 'stock' ||
                      controller.selectedType.value == 'fx')
                    const SizedBox(height: 12),
                  TextField(
                    controller: controller.principalController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
                    ],
                    decoration: const InputDecoration(labelText: 'Anapara'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.currentValueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
                    ],
                    decoration: const InputDecoration(labelText: 'Güncel değer'),
                  ),
                  if (controller.selectedType.value == 'deposit') ...[
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
                        labelText: 'Vade oranı (%)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller.monthlyYieldController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*[.,]?\d{0,2}'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Aylık kazanç',
                      ),
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
                colors: [Color(0xFF111827), Color(0xFF7C3AED)],
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
              'Vade oranı: ${investment.maturityRate?.toStringAsFixed(2) ?? '-'}% • Aylık kazanç: ${investment.monthlyYield == null ? '-' : AppFormatters.currency(investment.monthlyYield!)}',
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
        return 'Altın';
      case 'fx':
        return symbol == null || symbol.isEmpty ? 'Döviz' : 'Döviz • $symbol';
      case 'deposit':
        return 'TL Vadeli';
      case 'stock':
        return symbol == null || symbol.isEmpty ? 'Borsa' : 'Borsa • $symbol';
      default:
        return type;
    }
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
            'Altın, döviz, borsa veya TL vadeli yatırımlarını burada izleyebilirsin.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Yatırım ekle'),
          ),
        ],
      ),
    );
  }
}
