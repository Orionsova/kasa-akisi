import 'package:flutter/material.dart';

class CurrencyText extends StatelessWidget {
  const CurrencyText(
    this.value, {
    required this.style,
    this.textAlign,
    super.key,
  });

  final String value;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    if (value.contains('•')) {
      return Text(value, style: style, textAlign: textAlign);
    }

    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final currencyIndex = value.indexOf('₺');
    final hasCurrencySymbol = currencyIndex != -1;
    final symbol = hasCurrencySymbol ? '₺' : '';
    final rest = hasCurrencySymbol
        ? value.substring(currencyIndex + 1).trimLeft()
        : value;

    if (!rest.contains(',')) {
      if (!hasCurrencySymbol) {
        return Text(value, style: style, textAlign: textAlign);
      }
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$symbol ',
              style: baseStyle.copyWith(
                fontSize: (baseStyle.fontSize ?? 16) * 0.74,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: (baseStyle.color ?? Colors.black).withValues(alpha: 0.82),
              ),
            ),
            TextSpan(text: rest, style: baseStyle),
          ],
        ),
        textAlign: textAlign,
      );
    }

    final commaIndex = rest.lastIndexOf(',');
    if (commaIndex <= 0 || commaIndex >= rest.length - 1) {
      return Text(value, style: style, textAlign: textAlign);
    }
    final whole = rest.substring(0, commaIndex);
    final fraction = rest.substring(commaIndex);

    return Text.rich(
      TextSpan(
        children: [
          if (hasCurrencySymbol)
            TextSpan(
              text: '$symbol ',
              style: baseStyle.copyWith(
                fontSize: (baseStyle.fontSize ?? 16) * 0.74,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: (baseStyle.color ?? Colors.black).withValues(alpha: 0.82),
              ),
            ),
          TextSpan(text: whole, style: baseStyle),
          TextSpan(
            text: fraction,
            style: baseStyle.copyWith(
              fontSize: (baseStyle.fontSize ?? 16) * 0.66,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
      textAlign: textAlign,
    );
  }
}
