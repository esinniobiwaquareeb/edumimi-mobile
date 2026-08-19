String stripHtml(String input) {
  return input
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String formatMockMode(String mode) {
  switch (mode) {
    case 'FULL_MOCK':
      return 'Full mock';
    case 'TOPIC_DRILL':
      return 'Topic drill';
    case 'PAST_PAPER':
      return 'Past paper';
    default:
      return 'Practice';
  }
}
