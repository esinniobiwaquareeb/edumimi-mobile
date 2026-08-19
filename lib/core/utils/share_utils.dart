import 'package:flutter/material.dart';
import 'package:mock_mobile/core/config/app_config.dart';
import 'package:mock_mobile/core/constants/mock_voice.dart';
import 'package:mock_mobile/shared/models/mock_attempt.dart';
import 'package:share_plus/share_plus.dart';

/// Resolves the global rect of [context]'s render box for iOS/iPadOS share popovers.
Rect? sharePositionOriginFromContext(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Resolves the global rect of [key]'s render box for iOS/iPadOS share popovers.
Rect? sharePositionOriginFromKey(GlobalKey key) {
  final box = key.currentContext?.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Opens the native share sheet with [text].
Future<void> shareText(
  String text, {
  String? subject,
  Rect? sharePositionOrigin,
  BuildContext? context,
}) {
  final origin = sharePositionOrigin ?? (context != null ? sharePositionOriginFromContext(context) : null);
  return Share.share(text, subject: subject, sharePositionOrigin: origin);
}

/// Builds the score share message aligned with mock-frontend mock-share.ts.
String buildMockResultShareMessage({
  required String examTitle,
  required num percentScore,
  String? origin,
  bool isPreview = false,
  bool includeLeaderboard = false,
  String? referralLink,
}) {
  final webOrigin = origin ?? AppConfig.webShareOrigin;
  final trimmedReferralLink = referralLink?.trim();
  final referralLine = trimmedReferralLink != null && trimmedReferralLink.isNotEmpty
      ? ' Join with my link: $trimmedReferralLink'
      : '';

  if (isPreview) {
    return "I'm preparing for $examTitle on Edumimi and scored $percentScore% on my free preview.${referralLine.isNotEmpty ? referralLine : ' Try a free practice drill: $webOrigin'}";
  }

  final leaderboardLine = includeLeaderboard ? MockVoice.leaderboardShareRankLine : '';

  if (referralLine.isNotEmpty) {
    return 'I scored $percentScore% on $examTitle on Edumimi.$leaderboardLine$referralLine';
  }

  return 'I scored $percentScore% on $examTitle on Edumimi.$leaderboardLine Challenge yourself with free practice: $webOrigin/exams';
}

/// Builds the friend-challenge message aligned with mock-frontend mock-challenge.ts.
String buildChallengeShareMessage({
  required String challengerName,
  required String examTitle,
  required num percentScore,
  required String shareUrl,
}) {
  return '$challengerName scored $percentScore% on $examTitle on Edumimi. Take the same mock: $shareUrl';
}

String buildReferralShareMessage({required String referralLink, String? referralCode}) {
  final trimmedLink = referralLink.trim();
  if (trimmedLink.isNotEmpty) {
    return 'Join me on Edumimi Mock practice: $trimmedLink';
  }
  final trimmedCode = referralCode?.trim();
  if (trimmedCode != null && trimmedCode.isNotEmpty) {
    return 'Join me on Edumimi Mock practice. Use my referral code: $trimmedCode';
  }
  return 'Join me on Edumimi Mock practice: ${AppConfig.webShareOrigin}';
}

String buildParentShareMessage(String shareUrl) {
  return 'Track my exam prep on Edumimi (read-only): $shareUrl';
}

/// Heuristic for preview attempts when API previewSubmission is unavailable.
bool isPreviewAttempt(MockAttempt attempt) {
  final questions = attempt.exam?.questions ?? const [];
  return questions.any((question) => question.isLocked);
}

Future<void> shareMockResult({
  required String examTitle,
  required num percentScore,
  bool isPreview = false,
  bool includeLeaderboard = false,
  String? referralLink,
  Rect? sharePositionOrigin,
  BuildContext? context,
}) {
  return shareText(
    buildMockResultShareMessage(
      examTitle: examTitle,
      percentScore: percentScore,
      isPreview: isPreview,
      includeLeaderboard: includeLeaderboard,
      referralLink: referralLink,
    ),
    subject: 'My Edumimi score',
    sharePositionOrigin: sharePositionOrigin,
    context: context,
  );
}

Future<void> shareReferral({
  required String? referralLink,
  String? referralCode,
  Rect? sharePositionOrigin,
  BuildContext? context,
}) {
  return shareText(
    buildReferralShareMessage(
      referralLink: referralLink ?? '',
      referralCode: referralCode,
    ),
    subject: 'Edumimi referral',
    sharePositionOrigin: sharePositionOrigin,
    context: context,
  );
}

Future<void> shareParentProgressLink(
  String shareUrl, {
  Rect? sharePositionOrigin,
  BuildContext? context,
}) {
  return shareText(
    buildParentShareMessage(shareUrl),
    subject: 'My exam progress',
    sharePositionOrigin: sharePositionOrigin,
    context: context,
  );
}

Future<void> shareChallenge({
  required String challengerName,
  required String examTitle,
  required num percentScore,
  required String shareUrl,
  Rect? sharePositionOrigin,
  BuildContext? context,
}) {
  return shareText(
    buildChallengeShareMessage(
      challengerName: challengerName,
      examTitle: examTitle,
      percentScore: percentScore,
      shareUrl: shareUrl,
    ),
    subject: 'Edumimi challenge',
    sharePositionOrigin: sharePositionOrigin,
    context: context,
  );
}
