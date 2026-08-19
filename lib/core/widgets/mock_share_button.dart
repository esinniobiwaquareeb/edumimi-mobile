import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/core/utils/share_utils.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';

class MockShareButton extends StatelessWidget {
  const MockShareButton({
    super.key,
    required this.label,
    required this.onShare,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final Future<void> Function(Rect sharePositionOrigin)? onShare;
  final bool isLoading;
  final IconData? icon;

  Future<void> _handleShare(BuildContext context) async {
    final origin = sharePositionOriginFromContext(context);
    if (origin == null) return;
    await onShare?.call(origin);
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (buttonContext) {
        if (icon == null) {
          return MockSecondaryButton(
            label: isLoading ? 'Sharing…' : label,
            onPressed: isLoading ? null : () => _handleShare(buttonContext),
          );
        }

        return OutlinedButton.icon(
          onPressed: isLoading ? null : () => _handleShare(buttonContext),
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, size: 18),
          label: Text(isLoading ? 'Sharing…' : label),
        );
      },
    );
  }
}

class MockShareScoreButton extends StatelessWidget {
  const MockShareScoreButton({
    super.key,
    required this.examTitle,
    required this.percentScore,
    this.isPreview = false,
    this.includeLeaderboard = false,
    this.referralLink,
    this.label = 'Share score',
  });

  final String examTitle;
  final num percentScore;
  final bool isPreview;
  final bool includeLeaderboard;
  final String? referralLink;
  final String label;

  @override
  Widget build(BuildContext context) {
    return MockShareButton(
      label: label,
      icon: Icons.ios_share_outlined,
      onShare: (origin) => shareMockResult(
        examTitle: examTitle,
        percentScore: percentScore,
        isPreview: isPreview,
        includeLeaderboard: includeLeaderboard,
        referralLink: referralLink,
        sharePositionOrigin: origin,
      ),
    );
  }
}

class MockChallengeShareButton extends ConsumerStatefulWidget {
  const MockChallengeShareButton({
    super.key,
    required this.attemptId,
    required this.examTitle,
    required this.percentScore,
    this.challengerName = 'I',
    this.label = 'Challenge a friend',
  });

  final String attemptId;
  final String examTitle;
  final num percentScore;
  final String challengerName;
  final String label;

  @override
  ConsumerState<MockChallengeShareButton> createState() => _MockChallengeShareButtonState();
}

class _MockChallengeShareButtonState extends ConsumerState<MockChallengeShareButton> {
  var _isLoading = false;

  Future<void> _share(Rect sharePositionOrigin) async {
    setState(() => _isLoading = true);
    try {
      final challengeShare = await ref.read(mockPortalRepositoryProvider).fetchChallengeShare(widget.attemptId);
      await shareChallenge(
        challengerName: widget.challengerName,
        examTitle: widget.examTitle,
        percentScore: widget.percentScore,
        shareUrl: challengeShare.shareUrl,
        sharePositionOrigin: sharePositionOrigin,
      );
    } on ApiException catch (error) {
      if (mounted) {
        MockToast.error(context, error.message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MockShareButton(
      label: widget.label,
      icon: Icons.sports_martial_arts_outlined,
      isLoading: _isLoading,
      onShare: _share,
    );
  }
}
