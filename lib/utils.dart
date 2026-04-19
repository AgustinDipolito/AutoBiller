import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Utils {
  static String formatPrice(double price) =>
      '\$  ${NumberFormat("#,##0").format(price)}'.replaceAll(',', '.');
  static String formatDate(DateTime date) => DateFormat.yMd().format(date);
  static String formatDateNoYear(DateTime date) => '${date.day}/${date.month}';
}

class AppTheme {
  const AppTheme._();

  // Palette derived from current Colors.xxx usage across the app.
  static const Color primaryColor = Colors.blueGrey;
  static const Color secondaryColor = Colors.blue;
  static const Color tertiaryColor = Colors.orange;

  static const Color successColor = Colors.green;
  static const Color errorColor = Colors.red;
  static const Color acentosColor = Colors.orange;

  static const Color backgroundColor = Colors.white;
  static const Color cardsColor = Colors.white;
  static const Color typographyColor = Colors.black87;
  static const Color darkGreyColor = Colors.grey;

  // Spacing scale.
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 16.0;
  static const double spacingXLarge = 24.0;

  static const TextStyle bodySmallTextStyle = TextStyle(
    fontSize: 12,
    color: typographyColor,
  );

  static const TextStyle bodyTextStyle = TextStyle(
    fontSize: 14,
    color: typographyColor,
  );

  static const TextStyle subtitlesTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: typographyColor,
  );

  static const TextStyle subtitlesTextStyleBlack = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );
}
