import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:stategetx/core/formatters.dart';
import 'package:stategetx/models/app_transaction.dart';
import 'package:stategetx/modules/transaction/transaction_controller.dart';
import 'package:stategetx/modules/transaction/widgets/transaction_type_selection.dart';
import 'package:stategetx/themes/app_colors.dart';

class TransactionPage extends GetView<TransactionController> {
  const TransactionPage({super.key});

  void _showAddCategoryDialog(BuildContext context) {
    final categoryController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Yeni kategori'),
        content: TextField(
          controller: categoryController,
          decoration: const InputDecoration(
            hintText: 'Kategori adı',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await controller.createCategory(categoryController.text);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('tr', 'TR'),
      initialDate: controller.selectedDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != controller.selectedDate.value) {
      controller.selectedDate.value = picked;
    }
  }

  Widget _buildCardPaymentForm(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kart Borcu Ödeme',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            // Kart Seçimi
            Text(
              'Kart Seçin',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (controller.creditCards.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Henüz kredi kartı eklenmemiş',
                  textAlign: TextAlign.center,
                ),
              )
            else
              Obx(
                () => Column(
                  children: controller.creditCards
                      .map(
                        (card) => RadioListTile<String?>(
                          contentPadding: EdgeInsets.zero,
                          title: Text(card.name),
                          subtitle: Text(
                            'Toplam borç: ${card.currentDebt.toStringAsFixed(2)}₺',
                          ),
                          value: card.id,
                          groupValue: controller.selectedCardForPaymentId.value,
                          onChanged: (value) {
                            controller.selectedCardForPaymentId.value = value;
                            if (value != null) {
                              controller.setCardPaymentAmountToThisMonth();
                            }
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            const SizedBox(height: 22),
            // Mevcut Borç Gösterimi
            Obx(() {
              final card = controller.selectedCardForPayment;
              if (card == null) {
                return const SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kartın Mevcut Borcu',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${card.currentDebt.toStringAsFixed(2)}₺',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bu ayın ödeme: ${card.installmentCurrentCycleTotal.toStringAsFixed(2)}₺',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              );
            }),
            // Ödeme Tutarı
            Text(
              'Ödeme Tutarı',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller.cardPaymentAmountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Tutar',
                hintText: '0.00',
                prefixText: '₺ ',
                prefixIcon: Icon(Icons.payments_rounded),
              ),
            ),
            const SizedBox(height: 18),
            // Tarih Seçimi
            InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppFormatters.shortDate(controller.selectedDate.value),
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.isLoading
                    ? null
                    : controller.createTransaction,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text('Borcu Öde'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionForm(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'İşlem Detayı',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            // Başlık
            TextField(
              controller: controller.titleTextController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Başlık',
                hintText: 'Örn. Market harcaması',
                prefixIcon: Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 14),
            // Açıklama
            TextField(
              controller: controller.descriptionTextController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                hintText: 'Kısa not ekleyebilirsin',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 14),
            // Tutar
            TextField(
              controller: controller.amountTextController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Tutar',
                hintText: '0.00',
                prefixText: '₺ ',
                prefixIcon: Icon(Icons.payments_rounded),
              ),
            ),
            const SizedBox(height: 14),
            // Tarih
            InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppFormatters.shortDate(controller.selectedDate.value),
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Kategoriler
            Row(
              children: [
                Text(
                  'Kategoriler',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAddCategoryDialog(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Yeni'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (controller.filteredCategories.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Bu işlem tipi için kategori yok. Yeni bir kategori ekleyin.',
                ),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: controller.filteredCategories.map((category) {
                  final selected =
                      category.id == controller.selectedCategoryId.value;
                  return ChoiceChip(
                    label: Text(category.name ?? '-'),
                    selected: selected,
                    selectedColor: AppColors.accent.withValues(alpha: 0.18),
                    checkmarkColor: AppColors.accent,
                    side: BorderSide(
                      color: selected
                          ? AppColors.accent
                          : colorScheme.outline.withValues(alpha: 0.12),
                    ),
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.accent
                          : colorScheme.onSurface,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    onSelected: (_) {
                      if (category.id != null) {
                        controller.selectedCategoryId.value = category.id!;
                      }
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: 22),
            // Ödeme Yöntemi
            Text(
              'Ödeme Yöntemi',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Obx(
              () => Column(
                children: [
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Nakit'),
                    value: 'cash',
                    groupValue: controller.paymentMethod.value,
                    onChanged: (value) {
                      if (value != null) {
                        controller.paymentMethod.value = value;
                      }
                    },
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Banka'),
                    value: 'bank',
                    groupValue: controller.paymentMethod.value,
                    onChanged: (value) {
                      if (value != null) {
                        controller.paymentMethod.value = value;
                      }
                    },
                  ),
                  if (controller.creditCards.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        children: controller.creditCards
                            .map(
                              (card) => RadioListTile<String>(
                                contentPadding: EdgeInsets.zero,
                                title: Text(card.name),
                                subtitle: Text(
                                  'Kalan limit: ${card.availableLimit.toStringAsFixed(2)}₺',
                                ),
                                value: card.id,
                                groupValue: controller.paymentMethod.value,
                                onChanged: (value) {
                                  if (value != null) {
                                    controller.paymentMethod.value = value;
                                  }
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.isLoading
                    ? null
                    : controller.createTransaction,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text('İşlemi Kaydet'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Yeni İşlem')),
      body: Obx(
        () => Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF111827), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Akışını kaydet',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gelir, gider ve kart işlemlerini takip et.',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const TransactionTypeSelector(),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Obx(
                  () => controller.operationType.value == 'card-payment'
                      ? _buildCardPaymentForm(context, theme, colorScheme)
                      : _buildTransactionForm(context, theme, colorScheme),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      'Kaydedilen İşlemler',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${controller.transactions.length} kayıt',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (controller.transactions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 48,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Henüz işlem yok',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...controller.transactions.map(
                    (transaction) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TransactionCard(
                        transaction: transaction,
                        onDelete: () =>
                            controller.deleteTransaction(transaction.id),
                      ),
                    ),
                  ),
              ],
            ),
            if (controller.isLoading)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Kayıt işlemi sürüyor...'),
                      ],
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

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction, required this.onDelete});

  final AppTransaction transaction;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = transaction.isIncome ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              transaction.isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.category,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppFormatters.shortDate(transaction.date),
                  style: theme.textTheme.labelSmall?.copyWith(
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
                '${transaction.isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(2)}₺',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.close_rounded),
                iconSize: 20,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
