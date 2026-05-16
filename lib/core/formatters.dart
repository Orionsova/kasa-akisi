import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:stategetx/services/privacy_service.dart';

class AppFormatters {
  AppFormatters._();

  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  static final NumberFormat _amountFormatter = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '',
    decimalDigits: 2,
  );

  static String currency(double amount) {
    if (Get.isRegistered<PrivacyService>() &&
        Get.find<PrivacyService>().hideAmounts.value) {
      return '₺ •••••';
    }
    return _currencyFormatter.format(amount);
  }

  static String amountInput(double amount) {
    return _amountFormatter.format(amount).trim();
  }

  static double? parseCurrencyInput(String input) {
    final normalized = input
        .replaceAll('₺', '')
        .replaceAll('.', '')
        .replaceAll(' ', '')
        .replaceAll(',', '.')
        .trim();

    if (normalized.isEmpty) {
      return null;
    }

    return double.tryParse(normalized);
  }

  static String shortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  static String monthLabel(DateTime date) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  static String dayMonthLabel(DateTime date) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  static String monthYearLabel(DateTime date) {
    return monthLabel(DateTime(date.year, date.month));
  }
}
