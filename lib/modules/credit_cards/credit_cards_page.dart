import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:stategetx/core/formatters.dart';
import 'package:stategetx/core/input_formatters.dart';
import 'package:stategetx/core/widgets/currency_text.dart';
import 'package:stategetx/models/credit_card.dart';
import 'package:stategetx/models/credit_score_snapshot.dart';
import 'package:stategetx/modules/credit_cards/credit_cards_controller.dart';

class CreditCardsPage extends GetView<CreditCardsController> {
  const CreditCardsPage({super.key});

  Future<void> _pickInstallmentDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('tr', 'TR'),
      initialDate: controller.selectedInstallmentFirstPayment.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      controller.selectedInstallmentFirstPayment.value = picked;
    }
  }

  Future<void> _pickFuturePaymentMonth(BuildContext context) async {
    final selectedMonth = controller.selectedFuturePaymentMonth.value;
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('tr', 'TR'),
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      controller.selectedFuturePaymentMonth.value = DateTime(picked.year, picked.month);
    }
  }

  Future<void> _confirmDeleteCard(
    BuildContext context,
    CreditCardModel card,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Kart silinsin mi?'),
          content: Text(
            '${card.name} kartını silersen bu karta bağlı taksit ve gelecek dönem kayıtları da kaldırılır.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await controller.deleteCard(card.id);
    }
  }

  Future<void> _openCardDetails(
    BuildContext context,
    CreditCardModel card,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _CreditCardDetailPage(
          cardId: card.id,
          onEditCard: () => _showAddCardDialog(context, card: card),
          onDeleteCard: () => _confirmDeleteCard(context, card),
          onAddInstallment: () => _showAddInstallmentDialog(context, card),
          onEditInstallment: (installment) => _showAddInstallmentDialog(
            context,
            card,
            installment: installment,
          ),
          onDeleteInstallment: (installment) => controller.deleteInstallment(
            card.id,
            installment.id,
          ),
          onAddFuturePayment: () => _showAddFuturePaymentDialog(context, card),
        ),
      ),
    );
  }

  Future<void> _openScoreDetails(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _CreditScoreDetailsPage(),
      ),
    );
  }

  Future<void> _openAvailableLimitDetails(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _AvailableLimitDetailsPage(),
      ),
    );
  }

  Future<void> _openNextPeriodDetails(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _NextPeriodDetailsPage(),
      ),
    );
  }

  Future<void> _openTotalLimitDetails(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _TotalLimitDetailsPage(),
      ),
    );
  }

  Future<void> _openTotalDebtDetails(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _TotalDebtRankingPage(),
      ),
    );
  }

  void _showAddCardDialog(
    BuildContext context, {
    CreditCardModel? card,
  }) {
    if (card == null) {
      controller.clearForm();
    } else {
      controller.fillCardForm(card);
    }

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  card == null ? 'Kredi kartı ekle' : 'Kredi kartını düzenle',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller.nameController,
                  decoration: const InputDecoration(
                    labelText: 'Kart etiketi',
                    hintText: 'Örn. Ana kart, aile kartı, market kartı',
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Kart sahibi adını değiştir'),
                    subtitle: Text(
                      controller.useCustomCardholderName.value
                          ? 'Bu kart için profilden farklı bir isim kullanıyorsun'
                          : 'Varsayılan olarak profilindeki ad kart üstüne yazılır',
                    ),
                    value: controller.useCustomCardholderName.value,
                    onChanged: (value) {
                      controller.useCustomCardholderName.value = value;
                      if (!value) {
                        controller.cardholderNameController.text =
                            controller.cardholderName;
                      }
                    },
                  ),
                ),
                Obx(
                  () => AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: controller.cardholderNameController,
                        decoration: const InputDecoration(
                          labelText: 'Kart üzerinde görünecek isim',
                          hintText: 'Örn. AYSE YILMAZ',
                        ),
                      ),
                    ),
                    crossFadeState: controller.useCustomCardholderName.value
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 180),
                  ),
                ),
                TextField(
                  controller: controller.lastFourDigitsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Kartın son 4 hanesi',
                    hintText: 'İstersen boş bırakabilirsin',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Kart görünümü',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Renk ve beyaz ton katmanını seç. Uygulamanın her yerinde bu görünüm kullanılır.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () {
                    final option =
                        _cardPaletteMap[controller.selectedColorHex.value] ??
                            _cardPaletteOptions.first;
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.10),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 92,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: option.colors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Stack(
                              children: [
                                _CardFinishOverlay(
                                  shapeKey: controller.selectedShapeKey.value,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option.label,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '••••  ••••  ••••  ••••',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: Colors.white70,
                                              letterSpacing: 1.1,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _cardPaletteOptions.map((palette) {
                              final selected =
                                  controller.selectedColorHex.value == palette.key;
                              return InkWell(
                                onTap: () => controller.selectCardColor(palette.key),
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: palette.colors,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selected
                                          ? Theme.of(context).colorScheme.onSurface
                                          : Colors.white.withValues(alpha: 0.72),
                                      width: selected ? 2.2 : 1.2,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'Parlaklık tonu',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Obx(
                  () => Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _cardShapeOptions.map((shape) {
                      final selected =
                          controller.selectedShapeKey.value == shape.key;
                      return ChoiceChip(
                        label: Text(shape.label),
                        selected: selected,
                        onSelected: (_) => controller.selectCardShape(shape.key),
                        avatar: Icon(shape.icon, size: 18),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Aktif kullanılan kart'),
                    subtitle: const Text(
                      'Harcama, borç ve taksit gibi ödemeleri yaptığın kartı aktif olarak seçebilirsin.',
                    ),
                    value: controller.isActiveCard.value,
                    onChanged: (value) => controller.isActiveCard.value = value,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.limitController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [TurkishCurrencyInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Kart limiti'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller.availableLimitController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [TurkishCurrencyInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Mevcut limit',
                    hintText: 'Kartta şu an kullanılabilir kalan tutar',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.statementDayController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Tahmini hesap kesim günü',
                          hintText: 'Örn. 3',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: controller.paymentGraceDaysController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Kesimden sonra ödeme süresi',
                          hintText: 'Örn. 10 gün',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await controller.saveCard(cardId: card?.id);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(card == null ? 'Kartı kaydet' : 'Kartı güncelle'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddInstallmentDialog(
    BuildContext context,
    CreditCardModel card, {
    InstallmentPlan? installment,
  }) {
    if (installment == null) {
      controller.clearInstallmentForm();
    } else {
      controller.fillInstallmentForm(installment);
    }

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  installment == null
                      ? '${card.name} için taksit ekle'
                      : '${card.name} taksidini düzenle',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller.installmentTitleController,
                  decoration: const InputDecoration(labelText: 'Alışveriş adı'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller.installmentTotalController,
                  onChanged: (value) {
                    if (value.trim().isEmpty) {
                      controller.clearInstallmentFieldsIfOneIsEmpty();
                    }
                  },
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [TurkishCurrencyInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Toplam tutar'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller.installmentMonthlyController,
                  onChanged: (value) {
                    if (value.trim().isEmpty) {
                      controller.clearInstallmentFieldsIfOneIsEmpty();
                    }
                  },
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [TurkishCurrencyInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Aylık taksit'),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => InkWell(
                    onTap: () => _pickInstallmentDate(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'İlk ödeme: ${AppFormatters.shortDate(controller.selectedInstallmentFirstPayment.value)}',
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down_rounded),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.installmentCountController,
                        onChanged: (value) {
                          if (value.trim().isEmpty) {
                            controller.clearInstallmentFieldsIfOneIsEmpty();
                          }
                        },
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(labelText: 'Toplam taksit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: controller.installmentRemainingController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(labelText: 'Kalan taksit'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await controller.saveInstallment(
                        card.id,
                        installmentId: installment?.id,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(
                      installment == null
                          ? 'Taksiti kaydet'
                          : 'Taksiti güncelle',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddFuturePaymentDialog(BuildContext context, CreditCardModel card) {
    controller.clearFuturePaymentForm();

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${card.name} için gelecek dönem',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller.futurePaymentTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Ödeme adı',
                    hintText: 'Örn. Telefon taksiti',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller.futurePaymentAmountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [TurkishCurrencyInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Tutar'),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => InkWell(
                    onTap: () => _pickFuturePaymentMonth(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_note_rounded),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Dönem: ${AppFormatters.monthYearLabel(controller.selectedFuturePaymentMonth.value)}',
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down_rounded),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.futurePaymentInstallmentCountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Toplam taksit',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: controller.futurePaymentRemainingController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Kalan taksit',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await controller.addFuturePeriodPayment(card.id);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Gelecek aya ekle'),
                  ),
                ),
              ],
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
      () {
        final monthlyPaymentRatio = controller.totalLimit == 0
            ? 0.0
            : (controller.totalCurrentStatementDebt / controller.totalLimit)
                .clamp(0, 1)
                .toDouble();
        final summaryGradient = _summaryGradient(monthlyPaymentRatio);
        final cardScore = _creditScore(monthlyPaymentRatio);
        final availableLimitRatio = (1 - controller.utilizationRate).clamp(0, 1).toDouble();
        final fillTone = _fillTone(availableLimitRatio);

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            Row(
            children: [
              Text(
                'Kredi Kartları',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showAddCardDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Yeni kart'),
              ),
            ],
          ),
            const SizedBox(height: 16),
            Stack(
            children: [
              Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: summaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aylık toplam ödeme',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bu ay ödenecek toplam ekstre tutarı',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                          const SizedBox(height: 8),
                          CurrencyText(
                            AppFormatters.currency(controller.totalCurrentStatementDebt),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    _CreditScoreBox(
                      score: cardScore,
                      tone: fillTone,
                      onTap: () => _openScoreDetails(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _CardSummaryMetric(
                        label: 'Kullanılabilir limit',
                        value: AppFormatters.currency(controller.availableLimit),
                        onTap: () => _openAvailableLimitDetails(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CardSummaryMetric(
                        label: 'Gelecek ay',
                        value: AppFormatters.currency(controller.totalNextPeriodDebt),
                        onTap: () => _openNextPeriodDetails(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _CardSummaryMetric(
                        label: 'Toplam limit',
                        value: AppFormatters.currency(controller.totalLimit),
                        onTap: () => _openTotalLimitDetails(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CardSummaryMetric(
                        label: 'Toplam kalan borç',
                        value: AppFormatters.currency(controller.totalRemainingDebt),
                        onTap: () => _openTotalDebtDetails(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _UtilizationBar(
                  rate: availableLimitRatio,
                  tone: fillTone,
                ),
                ],
              ),
            ),
              _CardFinishOverlay(shapeKey: controller.selectedShapeKey.value),
            ],
          ),
            const SizedBox(height: 20),
            if (controller.cards.isEmpty)
              _CreditCardEmptyState(onAdd: () => _showAddCardDialog(context))
            else
              ...controller.cards.map(
                (card) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _CreditCardTile(
                    card: card,
                    onOpenDetails: () => _openCardDetails(context, card),
                    onEdit: () => _showAddCardDialog(context, card: card),
                    onDelete: () => _confirmDeleteCard(context, card),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CreditCardTile extends StatefulWidget {
  const _CreditCardTile({
    required this.card,
    required this.onOpenDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final CreditCardModel card;
  final VoidCallback onOpenDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_CreditCardTile> createState() => _CreditCardTileState();
}

class _CreditCardTileState extends State<_CreditCardTile> {
  bool _detailsVisible = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = widget.card;
    final controller = Get.find<CreditCardsController>();
    final style = _cardVisualStyle(card);
    final upcomingPayments = _buildUpcomingPayments(card);
    final usageRatio = card.limit == 0
        ? 0.0
        : ((card.currentDebt / card.limit).clamp(0, 1)).toDouble();

    return Column(
      children: [
        InkWell(
          onTap: widget.onOpenDetails,
          borderRadius: BorderRadius.circular(_cardCornerRadius(card)),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: style,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(_cardCornerRadius(card)),
                  boxShadow: [
                    BoxShadow(
                      color: style.last.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        card.isActive ? 'Aktif kart' : 'Pasif kart',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _cardBrandLabel(card),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          widget.onEdit();
                        } else {
                          widget.onDelete();
                        }
                      },
                      icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Kartı düzenle')),
                        PopupMenuItem(value: 'delete', child: Text('Kartı sil')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                      child: const Icon(
                        Icons.sim_card_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _cardMask(card.lastFourDigits),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  card.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                Obx(
                  () => Text(
                    _cardholderLabel(card, controller),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _statementSummary(card),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ),
                    Text(
                      card.lastFourDigits.trim().isEmpty ? 'Kart bilgisi' : '•••• ${_cardLastFourShort(card.lastFourDigits)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                  ],
                ),
              ),
              _CardFinishOverlay(shapeKey: card.shapeKey),
            ],
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => setState(() => _detailsVisible = !_detailsVisible),
          icon: Icon(
            _detailsVisible
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
          ),
          label: Text(_detailsVisible ? 'Detayları gizle' : 'Detayları göster'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
            side: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.18),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _CardInfo(
                          label: 'Bu ay',
                          value: AppFormatters.currency(card.currentStatementDebt),
                        ),
                      ),
                      Expanded(
                        child: _CardInfo(
                          label: 'Gelecek ay',
                          value: AppFormatters.currency(card.nextPeriodDebt),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: usageRatio,
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(style.last),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _CardInfo(
                          label: 'Kullanılabilir limit',
                          value: AppFormatters.currency(card.availableLimit),
                        ),
                      ),
                      Expanded(
                        child: _CardInfo(
                          label: 'Toplam limit',
                          value: AppFormatters.currency(card.limit),
                        ),
                      ),
                      Expanded(
                        child: _CardInfo(
                          label: 'Toplam borç',
                          value: AppFormatters.currency(card.currentDebt),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _CardInfo(
                          label: 'Doluluk oranı',
                          value: '%${(usageRatio * 100).toStringAsFixed(0)}',
                        ),
                      ),
                      Expanded(
                        child: _CardInfo(
                          label: 'Taksit',
                          value: '${card.installments.length} kayıt',
                        ),
                      ),
                      Expanded(
                        child: _CardInfo(
                          label: 'Gelecek ay',
                          value: '${upcomingPayments.length} kayıt',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          crossFadeState: _detailsVisible
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
      ],
    );
  }
}

class _CreditCardDetailPage extends StatelessWidget {
  const _CreditCardDetailPage({
    required this.cardId,
    required this.onEditCard,
    required this.onDeleteCard,
    required this.onAddInstallment,
    required this.onEditInstallment,
    required this.onDeleteInstallment,
    required this.onAddFuturePayment,
  });

  final String cardId;
  final VoidCallback onEditCard;
  final VoidCallback onDeleteCard;
  final VoidCallback onAddInstallment;
  final ValueChanged<InstallmentPlan> onEditInstallment;
  final ValueChanged<InstallmentPlan> onDeleteInstallment;
  final VoidCallback onAddFuturePayment;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CreditCardsController>();

    return Obx(() {
      final currentCard = controller.cards.firstWhereOrNull(
        (item) => item.id == cardId,
      );
      if (currentCard == null) {
        return const Scaffold(
          body: Center(child: Text('Kart bulunamadı')),
        );
      }

      final theme = Theme.of(context);
      final style = _cardVisualStyle(currentCard);
      final upcomingPayments = _buildUpcomingPayments(currentCard);
      final usageRatio = currentCard.limit == 0
          ? 0.0
          : ((currentCard.currentDebt / currentCard.limit).clamp(0, 1)).toDouble();
      final cardholderName = _cardholderLabel(currentCard, controller);

      return Scaffold(
        appBar: AppBar(
          title: Text(currentCard.name),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  onEditCard();
                } else {
                  onDeleteCard();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Kartı düzenle')),
                PopupMenuItem(value: 'delete', child: Text('Kartı sil')),
              ],
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned(
              top: -80,
              right: -50,
              child: _BlurOrb(
                color: style.last.withValues(alpha: 0.18),
                size: 220,
              ),
            ),
            Positioned(
              top: 180,
              left: -70,
              child: _BlurOrb(
                color: style.first.withValues(alpha: 0.10),
                size: 180,
              ),
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
            Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: style,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(_cardCornerRadius(currentCard) + 2),
                      boxShadow: [
                        BoxShadow(
                          color: style.last.withValues(alpha: 0.18),
                          blurRadius: 28,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                currentCard.isActive ? 'Aktif kart' : 'Pasif kart',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _cardBrandLabel(currentCard),
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.94),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                              child: const Icon(
                                Icons.sim_card_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _cardMask(currentCard.lastFourDigits),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          currentCard.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          cardholderName,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.86),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _statementSummary(currentCard),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.82),
                                ),
                              ),
                            ),
                            Text(
                              currentCard.lastFourDigits.trim().isEmpty
                                  ? 'Kart bilgisi'
                                  : '•••• ${_cardLastFourShort(currentCard.lastFourDigits)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _CardFinishOverlay(shapeKey: currentCard.shapeKey),
                ],
              ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _PremiumSummaryMetric(
                    label: 'Bu ay',
                    value: AppFormatters.currency(currentCard.currentStatementDebt),
                    tone: style.last,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PremiumSummaryMetric(
                    label: 'Gelecek ay',
                    value: AppFormatters.currency(currentCard.nextPeriodDebt),
                    tone: style.first,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _CardInfo(
                          label: 'Kullanılabilir limit',
                          value: AppFormatters.currency(currentCard.availableLimit),
                        ),
                      ),
                      Expanded(
                        child: _CardInfo(
                          label: 'Toplam limit',
                          value: AppFormatters.currency(currentCard.limit),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: usageRatio,
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(style.last),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _CardInfo(
                          label: 'Toplam kalan borç',
                          value: AppFormatters.currency(currentCard.currentDebt),
                        ),
                      ),
                      Expanded(
                        child: _CardInfo(
                          label: 'Doluluk oranı',
                          value: '%${(usageRatio * 100).toStringAsFixed(0)}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Taksitler',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAddInstallment,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Taksit ekle'),
              ),
            ],
          ),
            const SizedBox(height: 12),
            if (currentCard.installments.isEmpty)
              _EmptySectionCard(
                icon: Icons.receipt_long_rounded,
                title: 'Bu karta bağlı taksit yok',
                subtitle: 'Yeni taksit eklediğinde doğrudan ${currentCard.name} içinde görünür.',
              )
            else
              ...currentCard.installments.map(
                (installment) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InstallmentTile(
                    installment: installment,
                    accent: style.last,
                    onEdit: () => onEditInstallment(installment),
                    onDelete: () => onDeleteInstallment(installment),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Gelecek dönem',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 10),
              Text(
                AppFormatters.currency(
                  upcomingPayments.fold(0, (sum, item) => sum + item.amount),
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAddFuturePayment,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Kayıt ekle'),
              ),
            ],
          ),
            const SizedBox(height: 12),
            if (upcomingPayments.isEmpty)
              _EmptySectionCard(
                icon: Icons.event_note_rounded,
                title: 'Gelecek ay kaydı yok',
                subtitle: 'Önümüzdeki aylara ait ödemeleri burada kart bazında takip edebilirsin.',
              )
            else
              ..._groupUpcomingPaymentsByMonth(upcomingPayments).entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        collapsedShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        title: Text(
                          entry.key,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          '${entry.value.length} kayıt • ${AppFormatters.currency(entry.value.fold(0, (sum, item) => sum + item.amount))}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        children: entry.value
                            .map(
                              (payment) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _FuturePaymentTile(payment: payment),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _InstallmentTile extends StatelessWidget {
  const _InstallmentTile({
    required this.installment,
    required this.accent,
    required this.onEdit,
    required this.onDelete,
  });

  final InstallmentPlan installment;
  final Color accent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            accent.withValues(alpha: 0.035),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.receipt_long_rounded, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  installment.title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_installmentStatusText(installment.remainingInstallments, installment.totalInstallments)} • ${AppFormatters.shortDate(installment.firstPaymentDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Toplam ${AppFormatters.currency(installment.totalAmount)}',
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
                AppFormatters.currency(installment.monthlyAmount),
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Aylık',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else {
                    onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                  PopupMenuItem(value: 'delete', child: Text('Sil')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FuturePaymentTile extends StatelessWidget {
  const _FuturePaymentTile({required this.payment});

  final _UpcomingPaymentItem payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            payment.badgeColor.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.event_note_rounded, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: payment.badgeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: payment.badgeColor.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    payment.cardBadgeLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: payment.badgeColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  payment.dateContextText ?? payment.monthLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (payment.dateContextText != null && payment.installmentText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    payment.installmentText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppFormatters.currency(payment.amount),
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

List<_UpcomingPaymentItem> _buildUpcomingPayments(CreditCardModel card) {
  final now = DateTime.now();
  final items = <_UpcomingPaymentItem>[
    for (final installment in card.installments.where(
      (installment) => installment.remainingInstallments > 1,
    ))
      for (var offset = 1; offset < installment.remainingInstallments; offset++)
        _UpcomingPaymentItem(
          id: 'auto-${installment.id}-$offset',
          title: installment.title,
          cardLabel: card.lastFourDigits.trim().isEmpty
              ? card.name
              : '${card.name} • ${_cardLastFourShort(card.lastFourDigits)}',
          cardBadgeLabel: card.lastFourDigits.trim().isEmpty
              ? _cardBrandLabel(card)
              : '${_cardBrandLabel(card)} • ${_cardLastFourShort(card.lastFourDigits)}',
          badgeColor: _cardVisualStyle(card).last,
          monthDate: DateTime(now.year, now.month + offset),
          monthLabel: AppFormatters.monthYearLabel(
            DateTime(now.year, now.month + offset),
          ),
          amount: installment.monthlyAmount,
          installmentText: _installmentStatusText(
            installment.remainingInstallments - offset,
            installment.totalInstallments,
          ),
          dateContextText: _cycleDueContext(
            card,
            DateTime(now.year, now.month + offset),
          ),
          isAutomatic: true,
        ),
    ...card.futurePeriodPayments.map(
      (payment) => _UpcomingPaymentItem(
        id: payment.id,
        title: payment.title,
        cardLabel: card.lastFourDigits.trim().isEmpty
            ? card.name
            : '${card.name} • ${_cardLastFourShort(card.lastFourDigits)}',
        cardBadgeLabel: card.lastFourDigits.trim().isEmpty
            ? _cardBrandLabel(card)
            : '${_cardBrandLabel(card)} • ${_cardLastFourShort(card.lastFourDigits)}',
        badgeColor: _cardVisualStyle(card).last,
        monthDate: _parseMonthLabel(payment.monthLabel),
        monthLabel: payment.monthLabel,
        amount: payment.amount,
        installmentText: payment.totalInstallments == null
            ? null
            : _installmentStatusText(
                payment.remainingInstallments ?? 0,
                payment.totalInstallments!,
              ),
        dateContextText: null,
        isAutomatic: false,
      ),
    ),
  ];
  return items;
}

Map<String, List<_UpcomingPaymentItem>> _groupUpcomingPaymentsByMonth(
  List<_UpcomingPaymentItem> items,
) {
  final grouped = <String, List<_UpcomingPaymentItem>>{};
  final sortedItems = [...items]
    ..sort((a, b) => a.monthDate.compareTo(b.monthDate));
  for (final item in sortedItems) {
    grouped.putIfAbsent(item.monthLabel, () => []).add(item);
  }
  return grouped;
}

String _installmentStatusText(int remainingInstallments, int totalInstallments) {
  final safeTotal = totalInstallments <= 0 ? 1 : totalInstallments;
  final safeRemaining = remainingInstallments.clamp(0, safeTotal);
  final paid = safeTotal - safeRemaining;
  return '$paid ödendi • $safeRemaining kaldı';
}

class _UpcomingPaymentItem {
  const _UpcomingPaymentItem({
    required this.id,
    required this.title,
    required this.cardLabel,
    required this.cardBadgeLabel,
    required this.badgeColor,
    required this.monthDate,
    required this.monthLabel,
    required this.amount,
    required this.installmentText,
    required this.dateContextText,
    required this.isAutomatic,
  });

  final String id;
  final String title;
  final String cardLabel;
  final String cardBadgeLabel;
  final Color badgeColor;
  final DateTime monthDate;
  final String monthLabel;
  final double amount;
  final String? installmentText;
  final String? dateContextText;
  final bool isAutomatic;
}

DateTime _parseMonthLabel(String value) {
  const months = {
    'Ocak': 1,
    'Şubat': 2,
    'Mart': 3,
    'Nisan': 4,
    'Mayıs': 5,
    'Haziran': 6,
    'Temmuz': 7,
    'Ağustos': 8,
    'Eylül': 9,
    'Ekim': 10,
    'Kasım': 11,
    'Aralık': 12,
  };
  final parts = value.split(' ');
  if (parts.length != 2) {
    return DateTime.now();
  }
  final month = months[parts.first] ?? DateTime.now().month;
  final year = int.tryParse(parts.last) ?? DateTime.now().year;
  return DateTime(year, month);
}

class _EmptySectionCard extends StatelessWidget {
  const _EmptySectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardInfo extends StatelessWidget {
  const _CardInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        CurrencyText(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _CardSummaryMetric extends StatelessWidget {
  const _CardSummaryMetric({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
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
        ),
      ),
    );
  }
}

class _CreditScoreDetailsPage extends GetView<CreditCardsController> {
  const _CreditScoreDetailsPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skor Detayı'),
      ),
      body: Obx(() {
        final history = controller.scoreHistory.toList();
        final currentScore = controller.score;
        final topCard = controller.topSpendingCard;
        final previousScore = history.length > 1 ? history[1].score : null;
        final scoreChange = previousScore == null ? 0 : currentScore - previousScore;
        final topCards = controller.rankedCardsBySpending.take(3).toList();
        final fillTone = _fillTone((1 - controller.utilizationRate).clamp(0, 1).toDouble());
        final headerGradient = [
          const Color(0xFF111827),
          fillTone.withValues(alpha: 0.88),
        ];

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: headerGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: fillTone.withValues(alpha: 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aylık ödeme skoru',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              controller.scoreHeadline,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$currentScore',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '/100',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _DetailStatChip(
                          label: 'Bu ay ekstre',
                          value: AppFormatters.currency(
                            controller.totalCurrentStatementDebt,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DetailStatChip(
                          label: 'Kullanılabilir limit',
                          value: AppFormatters.currency(controller.availableLimit),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _DetailStatChip(
                          label: 'Skor değişimi',
                          value: previousScore == null
                              ? 'İlk kayıt'
                              : '${scoreChange >= 0 ? '+' : ''}$scoreChange puan',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DetailStatChip(
                          label: 'Riskte kart',
                          value: '${controller.highRiskCardCount} kart',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle(
              title: 'Skor Bileşenleri',
              subtitle: 'Bu kutu aylık ödeme yükünün limitlerine etkisini okuyor.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InsightMetricCard(
                    title: 'Aylık ödeme oranı',
                    value: '%${(controller.monthlyPaymentRatio * 100).round()}',
                    subtitle: 'Toplam limite göre',
                    tone: fillTone,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InsightMetricCard(
                    title: 'Aktif kart',
                    value: '${controller.cards.where((card) => card.isActive).length}',
                    subtitle: 'Kullanımda olan kart',
                    tone: fillTone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InsightMetricCard(
                    title: 'Toplam kalan borç',
                    value: AppFormatters.currency(controller.totalRemainingDebt),
                    subtitle: 'Limitten düşen toplam',
                    tone: fillTone,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InsightMetricCard(
                    title: 'Gelecek dönem',
                    value: AppFormatters.currency(controller.totalNextPeriodDebt),
                    subtitle: 'Önümüzdeki ay yükü',
                    tone: fillTone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionTitle(
              title: 'Harcama Lideri',
              subtitle: 'Bu ay ekstreye en çok yük bindiren kart.',
            ),
            const SizedBox(height: 12),
            if (topCard != null)
              _TopCardHighlight(card: topCard)
            else
              const _EmptyInfoCard(message: 'Henüz kart verisi yok.'),
            const SizedBox(height: 24),
            _SectionTitle(
              title: 'Kart Sıralaması',
              subtitle: 'Bu ayki ekstre yüküne göre üstten alta sıralandı.',
            ),
            const SizedBox(height: 12),
            if (topCards.isEmpty)
              const _EmptyInfoCard(message: 'Henüz sıralanacak kart görünmüyor.')
            else
              ...topCards.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RankedCardTile(
                    rank: entry.key + 1,
                    card: entry.value,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            _SectionTitle(
              title: 'Skor Geçmişi',
              subtitle: 'Son kayıtlar üzerinden puan değişimini takip et.',
            ),
            const SizedBox(height: 12),
            if (history.isEmpty)
              const _EmptyInfoCard(message: 'Skor geçmişi henüz oluşmadı.')
            else
              ...history.take(8).map(
                (snapshot) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ScoreHistoryTile(
                    snapshot: snapshot,
                    latestScore: currentScore,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            _SectionTitle(
              title: 'Kısa Notlar',
              subtitle: 'Skorun arkasındaki tabloyu hızlı okumak için.',
            ),
            const SizedBox(height: 12),
            ...controller.scoreInsights.map(
              (insight) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _InsightNote(
                  text: insight,
                  tone: fillTone,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _AvailableLimitDetailsPage extends GetView<CreditCardsController> {
  const _AvailableLimitDetailsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kullanılabilir Limit')),
      body: Obx(() {
        final cards = controller.cards.toList()
          ..sort((left, right) => right.availableLimit.compareTo(left.availableLimit));
        final topCard = cards.isEmpty ? null : cards.first;
        final tightestCard = cards.isEmpty ? null : (cards.toList()..sort(
          (left, right) => left.availableLimit.compareTo(right.availableLimit),
        )).first;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            _MetricDetailHero(
              title: 'Kullanılabilir limit',
              subtitle: 'Tüm kartlardaki şu an açık kalan alan.',
              value: AppFormatters.currency(controller.availableLimit),
              tone: const Color(0xFF2563EB),
              chips: [
                'Toplam limit ${AppFormatters.currency(controller.totalLimit)}',
                '${controller.cards.length} kart',
              ],
            ),
            const SizedBox(height: 24),
            if (topCard != null || tightestCard != null)
              Row(
                children: [
                  if (topCard != null)
                    Expanded(
                      child: _DetailMiniCard(
                        title: 'En rahat kart',
                        value: topCard.name,
                        subtitle: AppFormatters.currency(topCard.availableLimit),
                      ),
                    ),
                  if (topCard != null && tightestCard != null) const SizedBox(width: 12),
                  if (tightestCard != null)
                    Expanded(
                      child: _DetailMiniCard(
                        title: 'En sıkışık kart',
                        value: tightestCard.name,
                        subtitle: AppFormatters.currency(tightestCard.availableLimit),
                      ),
                    ),
                ],
              ),
            if (topCard != null || tightestCard != null) const SizedBox(height: 24),
            _SectionTitle(
              title: 'Kart Özeti',
              subtitle: 'Kalan limit oranına göre hızlı görünüm.',
            ),
            const SizedBox(height: 12),
            if (cards.isEmpty)
              const _EmptyInfoCard(message: 'Henüz kart görünmüyor.')
            else
              ...cards.map(
                (card) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AvailableLimitTile(card: card),
                ),
              ),
            const SizedBox(height: 24),
            _SectionTitle(
              title: 'Kısa Okuma',
              subtitle: 'Kalan limitin kartlara nasıl yayıldığı.',
            ),
            const SizedBox(height: 12),
            _InsightNote(
              text: topCard == null
                  ? 'Kart eklendiğinde burada kullanılabilir alan özeti görünür.'
                  : '${topCard.name} şu an en geniş nefes alan karta dönüşmüş görünüyor.',
              tone: const Color(0xFF2563EB),
            ),
            const SizedBox(height: 10),
            if (tightestCard != null)
              _InsightNote(
                text:
                    '${tightestCard.name} en düşük kullanılabilir limite sahip; bu kart limit baskısını önce burada hissediyor.',
                tone: const Color(0xFFDC2626),
              ),
          ],
        );
      }),
    );
  }
}

class _NextPeriodDetailsPage extends GetView<CreditCardsController> {
  const _NextPeriodDetailsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gelecek Ay Özet')),
      body: Obx(() {
        final cards = controller.cards.toList()
          ..sort((left, right) => right.nextPeriodDebt.compareTo(left.nextPeriodDebt));
        final payableCards = cards.where((card) => card.nextPeriodDebt > 0).toList();
        final topCard = payableCards.isEmpty ? null : payableCards.first;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            _MetricDetailHero(
              title: 'Gelecek ay toplamı',
              subtitle: 'Karta göre bir sonraki döneme taşınan yük.',
              value: AppFormatters.currency(controller.totalNextPeriodDebt),
              tone: const Color(0xFF7C3AED),
              chips: [
                '${payableCards.length} kartta ödeme var',
                AppFormatters.monthYearLabel(
                  DateTime(DateTime.now().year, DateTime.now().month + 1),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionTitle(
              title: 'Kart Bazlı Bekleyen Tutarlar',
              subtitle: 'Hangi kartta ne kadar gelecek ay yükü oluşmuş gör.',
            ),
            const SizedBox(height: 12),
            if (payableCards.isEmpty)
              const _EmptyInfoCard(message: 'Şu an gelecek aya taşınan kayıt görünmüyor.')
            else
              ...payableCards.map(
                (card) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _NextPeriodTile(card: card),
                ),
              ),
            const SizedBox(height: 24),
            _SectionTitle(
              title: 'Öne Çıkan Kart',
              subtitle: 'Gelecek dönem baskısının en yoğun olduğu yer.',
            ),
            const SizedBox(height: 12),
            if (topCard == null)
              const _EmptyInfoCard(message: 'Bekleyen gelecek ay ödemesi yok.')
            else
              _DetailMiniCard(
                title: topCard.name,
                value: AppFormatters.currency(topCard.nextPeriodDebt),
                subtitle:
                    'Taksit ve ileri dönem kayıtları bu kartta daha yoğun görünüyor.',
              ),
          ],
        );
      }),
    );
  }
}

class _TotalLimitDetailsPage extends GetView<CreditCardsController> {
  const _TotalLimitDetailsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Toplam Limit')),
      body: Obx(() {
        final cards = controller.cards.toList()
          ..sort((left, right) => right.limit.compareTo(left.limit));
        final topCard = cards.isEmpty ? null : cards.first;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            _MetricDetailHero(
              title: 'Toplam limit',
              subtitle: 'Tüm kartların tanımlı tavanı.',
              value: AppFormatters.currency(controller.totalLimit),
              tone: const Color(0xFF0F766E),
              chips: [
                'Kullanılabilir ${AppFormatters.currency(controller.availableLimit)}',
                '${controller.cards.length} kart',
              ],
            ),
            const SizedBox(height: 24),
            if (topCard != null)
              _DetailMiniCard(
                title: 'En yüksek limit',
                value: topCard.name,
                subtitle: AppFormatters.currency(topCard.limit),
              ),
            if (topCard != null) const SizedBox(height: 24),
            _SectionTitle(
              title: 'Limit Dağılımı',
              subtitle: 'Kartların toplam limit içindeki payı.',
            ),
            const SizedBox(height: 12),
            if (cards.isEmpty)
              const _EmptyInfoCard(message: 'Henüz limit dağılımı oluşmadı.')
            else
              ...cards.map(
                (card) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TotalLimitTile(
                    card: card,
                    totalLimit: controller.totalLimit,
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _TotalDebtRankingPage extends GetView<CreditCardsController> {
  const _TotalDebtRankingPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Borç Sıralaması')),
      body: Obx(() {
        final cards = controller.cards.toList()
          ..sort((left, right) => right.currentDebt.compareTo(left.currentDebt));
        final topCard = cards.isEmpty ? null : cards.first;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            _MetricDetailHero(
              title: 'Toplam kalan borç',
              subtitle: 'Yüksekten düşüğe kart sıralaması.',
              value: AppFormatters.currency(controller.totalRemainingDebt),
              tone: const Color(0xFFDC2626),
              chips: [
                'Bu ay ${AppFormatters.currency(controller.totalCurrentStatementDebt)} ekstre',
                '${cards.length} kart sıralandı',
              ],
            ),
            const SizedBox(height: 24),
            if (topCard != null)
              _DetailMiniCard(
                title: 'En yüksek borç',
                value: topCard.name,
                subtitle: AppFormatters.currency(topCard.currentDebt),
              ),
            if (topCard != null) const SizedBox(height: 24),
            _SectionTitle(
              title: 'Kart Borç Sıralaması',
              subtitle: 'Toplam kullanılan limite göre en yüksekten en düşüğe.',
            ),
            const SizedBox(height: 12),
            if (cards.isEmpty)
              const _EmptyInfoCard(message: 'Henüz borç sıralaması oluşmadı.')
            else
              ...cards.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DebtRankingTile(
                    rank: entry.key + 1,
                    card: entry.value,
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MetricDetailHero extends StatelessWidget {
  const _MetricDetailHero({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.tone,
    required this.chips,
  });

  final String title;
  final String subtitle;
  final String value;
  final Color tone;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF111827),
            tone.withValues(alpha: 0.88),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: tone.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.76),
            ),
          ),
          const SizedBox(height: 12),
          CurrencyText(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips.map(
              (chip) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Text(
                  chip,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ).toList(),
          ),
        ],
      ),
    );
  }
}

class _DetailMiniCard extends StatelessWidget {
  const _DetailMiniCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          CurrencyText(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStatChip extends StatelessWidget {
  const _DetailStatChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
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

class _InsightMetricCard extends StatelessWidget {
  const _InsightMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.tone,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: tone.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          CurrencyText(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCardHighlight extends StatelessWidget {
  const _TopCardHighlight({required this.card});

  final CreditCardModel card;

  @override
  Widget build(BuildContext context) {
    final style = _cardVisualStyle(card);
    final ratio = card.limit == 0 ? 0.0 : (card.currentDebt / card.limit).clamp(0, 1).toDouble();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: style,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  card.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                card.lastFourDigits.trim().isEmpty
                    ? 'Kart bilgisi'
                    : '•••• ${_cardLastFourShort(card.lastFourDigits)}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          CurrencyText(
            AppFormatters.currency(card.currentStatementDebt),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bu ay ekstreye en çok yük bindiren kart',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 9,
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Kart borç oranı %${(ratio * 100).round()}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankedCardTile extends StatelessWidget {
  const _RankedCardTile({
    required this.rank,
    required this.card,
  });

  final int rank;
  final CreditCardModel card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = card.limit == 0
        ? 0.0
        : (card.currentStatementDebt / card.limit).clamp(0, 1).toDouble();
    final badgeTone = _tryParseHexColor(card.colorHex) ?? _cardVisualStyle(card).last;

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
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: badgeTone.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '$rank',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: badgeTone,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bu ay ${AppFormatters.currency(card.currentStatementDebt)} ekstre yükü',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '%${(ratio * 100).round()}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreHistoryTile extends StatelessWidget {
  const _ScoreHistoryTile({
    required this.snapshot,
    required this.latestScore,
  });

  final CreditScoreSnapshot snapshot;
  final int latestScore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = (snapshot.score / 100).clamp(0, 1).toDouble();
    final tone = _fillTone(
      snapshot.totalLimit <= 0
          ? 1
          : (snapshot.availableLimit / snapshot.totalLimit).clamp(0, 1).toDouble(),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppFormatters.dayMonthLabel(snapshot.createdAt),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${snapshot.score}/100',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: tone,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(tone),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ekstre ${AppFormatters.currency(snapshot.currentStatementDebt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '${snapshot.score - latestScore >= 0 ? '+' : ''}${snapshot.score - latestScore} puan',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightNote extends StatelessWidget {
  const _InsightNote({
    required this.text,
    required this.tone,
  });

  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tone.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: tone,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInfoCard extends StatelessWidget {
  const _EmptyInfoCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardFinishOverlay extends StatelessWidget {
  const _CardFinishOverlay({required this.shapeKey});

  final String shapeKey;

  @override
  Widget build(BuildContext context) {
    switch (shapeKey) {
      case 'metal_sheen':
        return Positioned(
          top: -10,
          right: -6,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: -0.32,
              child: Container(
                width: 150,
                height: 210,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0.06),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
            ),
          ),
        );
      case 'clean_light':
        return Positioned(
          top: 18,
          left: 18,
          right: 18,
          child: IgnorePointer(
            child: Container(
              height: 1.2,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.26),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        );
      case 'soft_gloss':
        return Positioned(
          top: -18,
          right: -18,
          child: IgnorePointer(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        );
      case 'diagonal_gloss':
      default:
        return Positioned(
          top: -18,
          right: -8,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: -0.36,
              child: Container(
                width: 140,
                height: 210,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.16),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(38),
                ),
              ),
            ),
          ),
        );
    }
  }
}

class _AvailableLimitTile extends StatelessWidget {
  const _AvailableLimitTile({required this.card});

  final CreditCardModel card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = _tryParseHexColor(card.colorHex) ?? _cardVisualStyle(card).last;
    final ratio = card.limit == 0
        ? 0.0
        : (card.availableLimit / card.limit).clamp(0, 1).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  card.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                card.lastFourDigits.trim().isEmpty
                    ? 'Kart bilgisi'
                    : '•••• ${_cardLastFourShort(card.lastFourDigits)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CurrencyText(
            AppFormatters.currency(card.availableLimit),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 9,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(tone),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kalan oran %${(ratio * 100).round()}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextPeriodTile extends StatelessWidget {
  const _NextPeriodTile({required this.card});

  final CreditCardModel card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = _tryParseHexColor(card.colorHex) ?? _cardVisualStyle(card).last;
    final upcomingItems = _buildUpcomingPayments(card);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  card.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${upcomingItems.length} kayıt',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: tone,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CurrencyText(
            AppFormatters.currency(card.nextPeriodDebt),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Gelecek ay beklenen toplam ödeme',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalLimitTile extends StatelessWidget {
  const _TotalLimitTile({
    required this.card,
    required this.totalLimit,
  });

  final CreditCardModel card;
  final double totalLimit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = _tryParseHexColor(card.colorHex) ?? _cardVisualStyle(card).last;
    final ratio = totalLimit == 0 ? 0.0 : (card.limit / totalLimit).clamp(0, 1).toDouble();

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
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                CurrencyText(
                  AppFormatters.currency(card.limit),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Toplam limit payı %${(ratio * 100).round()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: 7,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(tone),
                ),
                Center(
                  child: Text(
                    '%${(ratio * 100).round()}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtRankingTile extends StatelessWidget {
  const _DebtRankingTile({
    required this.rank,
    required this.card,
  });

  final int rank;
  final CreditCardModel card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = _tryParseHexColor(card.colorHex) ?? _cardVisualStyle(card).last;
    final ratio = card.limit == 0 ? 0.0 : (card.currentDebt / card.limit).clamp(0, 1).toDouble();

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
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '$rank',
              style: theme.textTheme.titleMedium?.copyWith(
                color: tone,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                CurrencyText(
                  AppFormatters.currency(card.currentDebt),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Borç oranı %${(ratio * 100).round()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditScoreBox extends StatelessWidget {
  const _CreditScoreBox({
    required this.score,
    required this.tone,
    required this.onTap,
  });

  final int score;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final highlightTone = Color.lerp(Colors.white, tone, 0.26)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: 84,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                tone.withValues(alpha: 0.38),
                tone.withValues(alpha: 0.22),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: tone.withValues(alpha: 0.72),
            ),
            boxShadow: [
              BoxShadow(
                color: tone.withValues(alpha: 0.24),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 30,
                height: 4,
                decoration: BoxDecoration(
                  color: highlightTone.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Skor',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: highlightTone.withValues(alpha: 0.94),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$score',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '/100',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: highlightTone.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumSummaryMetric extends StatelessWidget {
  const _PremiumSummaryMetric({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: tone.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: tone.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 4,
            decoration: BoxDecoration(
              color: tone,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          CurrencyText(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _UtilizationBar extends StatelessWidget {
  const _UtilizationBar({
    required this.rate,
    required this.tone,
  });

  final double rate;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Kart doluluk oranı',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            ),
            const Spacer(),
            Text(
              '%${(rate * 100).toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: rate,
            minHeight: 10,
            backgroundColor: Colors.white.withValues(alpha: 0.14),
            valueColor: AlwaysStoppedAnimation<Color>(tone),
          ),
        ),
      ],
    );
  }
}

List<Color> _summaryGradient(double utilizationRate) {
  final clampedRate = utilizationRate.clamp(0, 1).toDouble();
  final accent = Color.lerp(
    const Color(0xFF0F766E),
    const Color(0xFF92400E),
    clampedRate,
  )!;
  return [
    const Color(0xFF162032),
    accent.withValues(alpha: 0.92),
  ];
}

int _creditScore(double utilizationRate) {
  final score = (100 - (utilizationRate.clamp(0, 1) * 100)).round();
  return score.clamp(0, 100).toInt();
}

Color _fillTone(double utilizationRate) {
  final clampedRate = utilizationRate.clamp(0, 1).toDouble();
  return Color.lerp(
    const Color(0xFFDC2626),
    const Color(0xFF38BDF8),
    clampedRate,
  )!;
}

List<Color> _cardVisualStyle(CreditCardModel card) {
  final palette = _cardPaletteMap[card.colorHex];
  if (palette != null) {
    return palette.colors;
  }

  final parsed = _tryParseHexColor(card.colorHex);
  if (parsed != null) {
    return [parsed.withValues(alpha: 0.86), parsed];
  }
  return _cardPaletteMap['graphite_metal']!.colors;
}

String _cardBrandLabel(CreditCardModel card) {
  final label = card.name.trim();
  if (label.isEmpty) {
    return 'CARD';
  }
  return label.split(' ').first.toUpperCase();
}

String _cardMask(String lastFourDigits) {
  final digits = lastFourDigits.replaceAll(RegExp(r'\D'), '');
  final lastFour = digits.isEmpty ? '••••' : digits.padLeft(4, '0');
  return '••••  ••••  ••••  $lastFour';
}

String _cardLastFourShort(String lastFourDigits) {
  final digits = lastFourDigits.replaceAll(RegExp(r'\D'), '');
  return digits.isEmpty ? '••••' : digits.padLeft(4, '0');
}

double _cardCornerRadius(CreditCardModel card) {
  return 28;
}

String _cardholderLabel(CreditCardModel card, CreditCardsController controller) {
  return controller.cardholderNameForCard(card);
}

String _statementSummary(CreditCardModel card) {
  return 'Kesim yaklaşık ${card.statementDay} • ${card.paymentGraceDays} gün sonra ödeme';
}

String _cycleDueContext(CreditCardModel card, DateTime cycleMonth) {
  final statementDate = DateTime(cycleMonth.year, cycleMonth.month, card.statementDay);
  final dueDate = statementDate.add(Duration(days: card.paymentGraceDays));
  return 'Kesim ${AppFormatters.shortDate(statementDate)} • Son ödeme ${AppFormatters.shortDate(dueDate)}';
}

Color? _tryParseHexColor(String value) {
  final normalized = value.replaceAll('#', '');
  if (normalized.length != 6) {
    return null;
  }
  final colorValue = int.tryParse(normalized, radix: 16);
  if (colorValue == null) {
    return null;
  }
  return Color(0xFF000000 | colorValue);
}

class _CardPaletteOption {
  const _CardPaletteOption({
    required this.key,
    required this.label,
    required this.colors,
  });

  final String key;
  final String label;
  final List<Color> colors;
}

class _CardShapeOption {
  const _CardShapeOption({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;
}

const List<_CardPaletteOption> _cardPaletteOptions = [
  _CardPaletteOption(
    key: 'ember_red',
    label: 'Ember Red',
    colors: [Color(0xFF7F1D1D), Color(0xFFE11D48)],
  ),
  _CardPaletteOption(
    key: 'forest_green',
    label: 'Forest Green',
    colors: [Color(0xFF064E3B), Color(0xFF10B981)],
  ),
  _CardPaletteOption(
    key: 'cobalt_blue',
    label: 'Cobalt Blue',
    colors: [Color(0xFF0F2A66), Color(0xFF2563EB)],
  ),
  _CardPaletteOption(
    key: 'amber_gold',
    label: 'Amber Gold',
    colors: [Color(0xFF6B4F12), Color(0xFFC89211)],
  ),
  _CardPaletteOption(
    key: 'midnight_navy',
    label: 'Midnight Navy',
    colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
  ),
  _CardPaletteOption(
    key: 'plum_violet',
    label: 'Plum Violet',
    colors: [Color(0xFF312E81), Color(0xFF7C3AED)],
  ),
  _CardPaletteOption(
    key: 'graphite_metal',
    label: 'Grafit Metal',
    colors: [Color(0xFF2D3748), Color(0xFF7C8594)],
  ),
  _CardPaletteOption(
    key: 'silver_metal',
    label: 'Gümüş Metal',
    colors: [Color(0xFF71717A), Color(0xFFE4E4E7)],
  ),
  _CardPaletteOption(
    key: 'black_titanium',
    label: 'Siyah Titanyum',
    colors: [Color(0xFF0A0A0A), Color(0xFF52525B)],
  ),
  _CardPaletteOption(
    key: 'rose_gold',
    label: 'Rose Gold',
    colors: [Color(0xFF9A3412), Color(0xFFF59E8B)],
  ),
  _CardPaletteOption(
    key: 'emerald_glow',
    label: 'Emerald Glow',
    colors: [Color(0xFF065F46), Color(0xFF34D399)],
  ),
  _CardPaletteOption(
    key: 'espresso_brown',
    label: 'Espresso Brown',
    colors: [Color(0xFF3F2A1D), Color(0xFF9A6B4F)],
  ),
  _CardPaletteOption(
    key: 'pearl_white',
    label: 'Pearl White',
    colors: [Color(0xFFBFC7D4), Color(0xFFF8FAFC)],
  ),
  _CardPaletteOption(
    key: 'sunset_coral',
    label: 'Sunset Coral',
    colors: [Color(0xFFBE123C), Color(0xFFFB7185)],
  ),
];

const List<_CardShapeOption> _cardShapeOptions = [
  _CardShapeOption(
    key: 'soft_gloss',
    label: 'Soft',
    icon: Icons.auto_awesome_rounded,
  ),
  _CardShapeOption(
    key: 'diagonal_gloss',
    label: 'Diyagonal',
    icon: Icons.show_chart_rounded,
  ),
  _CardShapeOption(
    key: 'metal_sheen',
    label: 'Metal',
    icon: Icons.layers_rounded,
  ),
  _CardShapeOption(
    key: 'clean_light',
    label: 'Minimal',
    icon: Icons.horizontal_rule_rounded,
  ),
];

final Map<String, _CardPaletteOption> _cardPaletteMap = {
  for (final option in _cardPaletteOptions) option.key: option,
};

class _CreditCardEmptyState extends StatelessWidget {
  const _CreditCardEmptyState({required this.onAdd});

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
          const Icon(Icons.credit_card_rounded, size: 42),
          const SizedBox(height: 14),
          Text(
            'Henüz kart eklenmemiş',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Kart limitlerini, son ödeme günlerini ve taksitlerini burada takip edebilirsin.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Kart ekle'),
          ),
        ],
      ),
    );
  }
}
