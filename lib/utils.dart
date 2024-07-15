import 'package:intl/intl.dart';

class Utils {
  static String formatPrice(double price) =>
      '\$  ${NumberFormat("#,##0").format(price)}'.replaceAll(',', '.');
  static String formatDate(DateTime date) => DateFormat.yMd().format(date);
  static String formatDateNoYear(DateTime date) => '${date.day}/${date.month}';
}
