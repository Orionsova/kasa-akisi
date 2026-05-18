import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:stategetx/core/formatters.dart';

class TurkishCurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final amount = double.parse(digitsOnly) / 100;
    final formatted = AppFormatters.amountInput(amount);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class TurkishGroupedNumberInputFormatter extends TextInputFormatter {
  TurkishGroupedNumberInputFormatter({this.decimalRange = 2})
    : _formatter = NumberFormat.decimalPattern('tr_TR');

  final int decimalRange;
  final NumberFormat _formatter;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(RegExp(r'[^0-9,]'), '');
    if (raw.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final parts = raw.split(',');
    final integerPart = parts.first.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final normalizedInteger = integerPart.isEmpty ? '0' : integerPart;
    final formattedInteger = _formatter.format(int.parse(normalizedInteger));
    final decimalPart = parts.length > 1
        ? parts.sublist(1).join().substring(
            0,
            parts.sublist(1).join().length.clamp(0, decimalRange),
          )
        : '';

    final text = decimalPart.isEmpty
        ? formattedInteger
        : '$formattedInteger,$decimalPart';

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
