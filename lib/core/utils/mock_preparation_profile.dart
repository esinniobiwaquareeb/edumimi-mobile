bool resolvePracticeTimerEnabled(bool? value) {
  return value ?? true;
}

bool resolveExamTimerEnabled(String? examMode, bool practiceTimerEnabled) {
  if (examMode == 'FULL_MOCK' || examMode == 'PAST_PAPER') {
    return true;
  }
  return practiceTimerEnabled;
}
