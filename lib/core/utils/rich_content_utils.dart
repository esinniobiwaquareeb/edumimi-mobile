class MathToken {
  const MathToken({required this.expression, required this.displayMode});

  final String expression;
  final bool displayMode;
}

final RegExp mathTokenRegex = RegExp(
  r'(\$\$[\s\S]+?\$\$|\\\[[\s\S]+?\\\]|\\\([\s\S]+?\\\)|\$[^$\n]+\$)',
);

final RegExp htmlTagRegex = RegExp(
  r'<\/?(?:sup|sub|b|i|em|strong|br|p|span|u|small|blockquote|ul|ol|li|div|table|tr|td|th|thead|tbody|hr|mark)[^>]*>',
  caseSensitive: false,
);

bool containsHtmlMarkup(String value) {
  return htmlTagRegex.hasMatch(value);
}

bool hasMathContent(String value) {
  return mathTokenRegex.hasMatch(value);
}

MathToken? normalizeMathToken(String token) {
  if (token.startsWith(r'$$') && token.endsWith(r'$$')) {
    return MathToken(expression: token.substring(2, token.length - 2).trim(), displayMode: true);
  }

  if (token.startsWith(r'\[') && token.endsWith(r'\]')) {
    return MathToken(expression: token.substring(2, token.length - 2).trim(), displayMode: true);
  }

  if (token.startsWith(r'\(') && token.endsWith(r'\)')) {
    return MathToken(expression: token.substring(2, token.length - 2).trim(), displayMode: false);
  }

  if (token.startsWith(r'$') && token.endsWith(r'$')) {
    return MathToken(expression: token.substring(1, token.length - 1).trim(), displayMode: false);
  }

  return null;
}

List<String> splitRichContent(String value) {
  final parts = <String>[];
  var start = 0;

  for (final match in mathTokenRegex.allMatches(value)) {
    if (match.start > start) {
      parts.add(value.substring(start, match.start));
    }
    parts.add(match.group(0)!);
    start = match.end;
  }

  if (start < value.length) {
    parts.add(value.substring(start));
  }

  return parts.where((part) => part.isNotEmpty).toList();
}

String normalizeContentFormat(String? format) {
  return format?.trim().toUpperCase() ?? 'PLAIN';
}
