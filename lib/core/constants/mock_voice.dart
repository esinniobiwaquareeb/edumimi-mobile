import 'package:intl/intl.dart';

/// Student-friendly product copy aligned with mock-frontend mock-voice.ts.
abstract final class MockVoice {
  static const brandTagline = 'Exam practice for JAMB, WAEC & NECO';
  static const leaderboardShareRankLine = " I just ranked among Edumimi's top students.";

  static const logOutTitle = 'Log out?';
  static const logOutDesc = 'You can log back in anytime to continue where you stopped.';
  static const logOut = 'Log out';

  static const submitExamTitle = 'All done?';
  static const submitExamConfirm = "Yes, I'm done!";
  static const submitExamKeepGoing = 'Keep going';
  static const submitExamDefaultDesc =
      "Are you sure you want to hand in your exam? You can't change your answers after this.";

  static const exitExamTitle = 'Exit exam?';
  static const exitExamDesc =
      'Are you sure you want to leave the exam workspace? Your progress is saved, but the timer will continue running.';
  static const exitExamConfirm = 'Yes, exit';
  static const exitExamStay = 'Stay';

  static const removeAvatarTitle = 'Remove profile photo?';
  static const removeAvatarDesc = 'Your initials will show on your profile instead.';
  static const removeAvatarConfirm = 'Remove';

  static const redeemLicenseTitle = 'Redeem license?';
  static const redeemLicenseDesc = 'This will add the school license to your account.';
  static const redeemLicenseConfirm = 'Redeem code';

  static const cancelPaymentTitle = 'Cancel payment?';
  static const cancelPaymentDesc = 'You can return to packages and complete checkout later.';
  static const cancelPaymentConfirm = 'Leave checkout';
  static const cancelPaymentStay = 'Stay';

  static const cancel = 'Cancel';

  static const continueAttemptLabel = 'Continue where you left off';
  static const continueAttemptCta = 'Continue exam';
  static const unlockUpsellTitle = 'Ready for full access?';
  static const unlockUpsellBody =
      'Free practice stops at your preview limit. Full access unlocks the complete bank and timed mocks.';
  static const unlockUpsellCta = 'Get full access';

  static const transactionPinSetupTitle = 'Set up a transaction PIN';
  static const transactionPinSetupBody =
      'Create a 4–6 digit PIN in your profile before you can pay for packages.';
  static const transactionPinPromptTitle = 'Enter transaction PIN';
  static const transactionPinPromptBody = 'Confirm your 4–6 digit PIN to continue to secure checkout.';
  static const transactionPinGoToProfile = 'Go to profile';
  static const transactionPinContinuePayment = 'Continue to payment';
  static const transactionPinSectionTitle = 'Transaction PIN';
  static const transactionPinSectionBody = 'Use a 4–6 digit PIN to authorize package payments securely.';
  static const transactionPinCreateCta = 'Create transaction PIN';
  static const transactionPinUpdateCta = 'Update transaction PIN';

  static const leaderboardTableWhen = 'Period';
  static const leaderboardPrizesTitle = 'Top student rewards';
  static const leaderboardPrizesBody =
      'Top scorers each week earn bonus practice credits and streak boosts. Keep practicing and submit full exams to qualify.';
  static const leaderboardCtaTitle = 'Want to join the top students?';
  static const leaderboardCtaBody =
      'Free practice only scores your preview questions. Get full access to submit complete exams and rank with the best.';
  static const leaderboardCtaButton = 'Get full access';

  static const onboardingPages = [
    MockOnboardingPage(
      iconName: 'menu_book_outlined',
      title: 'Practice anytime',
      body: 'Run a free mock in minutes. JAMB, WAEC, NECO and scholarship drills stay free to try.',
    ),
    MockOnboardingPage(
      iconName: 'wifi_off_outlined',
      title: 'Works offline',
      body: 'Download practice questions and keep studying when your connection drops.',
    ),
    MockOnboardingPage(
      iconName: 'bar_chart_outlined',
      title: 'Track your progress',
      body: 'Check your scores, spot weak topics, and see how you improve over time.',
    ),
    MockOnboardingPage(
      iconName: 'emoji_events_outlined',
      title: 'Climb the rankings',
      body: 'Submit full exams, join the top students list, and share wins with your study squad.',
    ),
  ];

  static String leaderboardPeriodLabel(String period) {
    return switch (period) {
      'month' => 'This month',
      'all' => 'All time',
      _ => 'This week',
    };
  }

  static String formatLeaderboardDate(String submittedAt) {
    if (submittedAt.isEmpty) {
      return '—';
    }
    final parsed = DateTime.tryParse(submittedAt);
    if (parsed == null) {
      return '—';
    }
    return DateFormat.yMMMd('en_NG').format(parsed.toLocal());
  }
}

class MockOnboardingPage {
  const MockOnboardingPage({
    required this.iconName,
    required this.title,
    required this.body,
  });

  final String iconName;
  final String title;
  final String body;
}
