import 'package:intl/intl.dart';

class MockDateTime {
  const MockDateTime._();

  static String dateTime(String? value, {String fallback = '—'}) {
    final parsed = value == null ? null : DateTime.tryParse(value);
    if (parsed == null) {
      return fallback;
    }
    return _format(parsed, 'd MMM yyyy, h:mm a', fallback);
  }

  static String compactDateTime(String? value, {String fallback = '—'}) {
    final parsed = value == null ? null : DateTime.tryParse(value);
    if (parsed == null) {
      return fallback;
    }
    return _format(parsed, 'd MMM, h:mm a', fallback);
  }

  static String date(String? value, {String fallback = '—'}) {
    final parsed = value == null ? null : DateTime.tryParse(value);
    if (parsed == null) {
      return fallback;
    }
    return _format(parsed, 'd MMM yyyy', fallback);
  }

  static String time(String? value, {String fallback = ''}) {
    final parsed = value == null ? null : DateTime.tryParse(value);
    if (parsed == null) {
      return fallback;
    }
    return _format(parsed, 'h:mm a', fallback);
  }

  static String _format(DateTime value, String pattern, String fallback) {
    try {
      return DateFormat(pattern).format(value.toLocal());
    } catch (_) {
      return fallback;
    }
  }
}
