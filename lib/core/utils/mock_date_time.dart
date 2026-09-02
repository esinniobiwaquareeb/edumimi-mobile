import 'package:intl/intl.dart';

class MockDateTime {
  const MockDateTime._();

  static String dateTime(String? value, {String fallback = '—'}) {
    final parsed = value == null ? null : DateTime.tryParse(value);
    if (parsed == null) {
      return fallback;
    }
    return DateFormat('d MMM yyyy, h:mm a', 'en_NG').format(parsed.toLocal());
  }

  static String compactDateTime(String? value, {String fallback = '—'}) {
    final parsed = value == null ? null : DateTime.tryParse(value);
    if (parsed == null) {
      return fallback;
    }
    return DateFormat('d MMM, h:mm a', 'en_NG').format(parsed.toLocal());
  }

  static String date(String? value, {String fallback = '—'}) {
    final parsed = value == null ? null : DateTime.tryParse(value);
    if (parsed == null) {
      return fallback;
    }
    return DateFormat('d MMM yyyy', 'en_NG').format(parsed.toLocal());
  }

  static String time(String? value, {String fallback = ''}) {
    final parsed = value == null ? null : DateTime.tryParse(value);
    if (parsed == null) {
      return fallback;
    }
    return DateFormat('h:mm a', 'en_NG').format(parsed.toLocal());
  }
}
