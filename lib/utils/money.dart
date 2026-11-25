import 'package:intl/intl.dart';

class Money {
  static final NumberFormat _format = NumberFormat.currency(
    locale: 'en_US',
    symbol: 'S/ ',
    decimalDigits: 2,
  );

  static String format(num value) => _format.format(value);

  static double? tryParse(String input) {
    var cleaned = input.trim().replaceAll('S/', '').replaceAll(' ', '');
    if (cleaned.isEmpty) {
      return null;
    }
    if (cleaned.contains(',') && cleaned.contains('.')) {
      cleaned = cleaned.replaceAll(',', '');
    } else if (cleaned.contains(',') && !cleaned.contains('.')) {
      final parts = cleaned.split(',');
      if (parts.length == 2 && parts.last.length <= 2) {
        cleaned = '${parts.first.replaceAll('.', '')}.${parts.last}';
      } else {
        cleaned = cleaned.replaceAll(',', '');
      }
    }
    return double.tryParse(cleaned);
  }
}
