import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/constants/mock_voice.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/core/offline/connectivity_service.dart';
import 'package:mock_mobile/core/offline/offline_sync_service.dart';
import 'package:mock_mobile/core/offline/pending_submit_queue.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
import 'package:mock_mobile/core/theme/theme_context.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/widgets/mock_rich_content.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';
import 'package:mock_mobile/shared/models/mock_exam.dart';

class ExamSessionScreen extends ConsumerStatefulWidget {
  const ExamSessionScreen({super.key, required this.slug, this.attemptId, this.sessionId});

  final String slug;
  final String? attemptId;
  final String? sessionId;

  @override
  ConsumerState<ExamSessionScreen> createState() => _ExamSessionScreenState();
}

class _ExamSessionScreenState extends ConsumerState<ExamSessionScreen> {
  StartAttemptResponse? _session;
  var _currentIndex = 0;
  final Map<String, int> _answers = {};
  final Map<String, bool> _markedForReview = {};
  var _isLoading = true;
  var _isSubmitting = false;
  var _isOfflineSession = false;
  var _showRecoveryNotice = false;
  var _timeLeft = 0;
  var _warnedFiveMinutes = false;
  var _warnedOneMinute = false;
  String? _error;
  late DateTime _startedAt;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    unawaited(_loadSession());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSession() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sessionId = widget.sessionId ?? DateTime.now().millisecondsSinceEpoch.toString();
      final response = await ref.read(mockPortalRepositoryProvider).startExam(widget.slug, sessionId: sessionId);
      await ref.read(offlinePracticeCacheProvider).cacheExamQuestions(response.exam);
      _applySession(response);
      setState(() {
        _isOfflineSession = false;
        _isLoading = false;
      });
      await _persistProgress();
      _startCountdown();
    } on ApiException catch (error) {
      final restored = _restoreSavedSession();
      if (restored) {
        _startCountdown();
        return;
      }
      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    }
  }

  void _applySession(StartAttemptResponse response) {
    final saved = ref.read(examSessionStoreProvider).getSessionForSlug(widget.slug);
    final totalSeconds = response.exam.durationMinutes * 60;

    if (saved != null && saved.attemptId == response.attemptId) {
      _session = response;
      _answers
        ..clear()
        ..addAll(saved.answers);
      _markedForReview
        ..clear()
        ..addAll(saved.markedForReview);
      _currentIndex = saved.currentIndex;
      _startedAt = saved.startedAt;
      _timeLeft = saved.timeLeftSeconds > 0 ? saved.timeLeftSeconds : totalSeconds;
      _showRecoveryNotice = true;
      return;
    }

    _session = response;
    _answers.clear();
    _markedForReview.clear();
    _currentIndex = 0;
    _startedAt = DateTime.now();
    _timeLeft = totalSeconds;
    _showRecoveryNotice = response.resumed;
  }

  bool _restoreSavedSession() {
    final saved = ref.read(examSessionStoreProvider).getSessionForSlug(widget.slug);
    if (saved == null) {
      return false;
    }

    setState(() {
      _session = StartAttemptResponse(
        attemptId: saved.attemptId,
        exam: saved.exam,
        resumed: true,
      );
      _answers
        ..clear()
        ..addAll(saved.answers);
      _markedForReview
        ..clear()
        ..addAll(saved.markedForReview);
      _currentIndex = saved.currentIndex;
      _startedAt = saved.startedAt;
      _timeLeft = saved.timeLeftSeconds > 0
          ? saved.timeLeftSeconds
          : saved.exam.durationMinutes * 60;
      _isOfflineSession = true;
      _isLoading = false;
      _error = null;
      _showRecoveryNotice = true;
    });
    return true;
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tickTimer());
  }

  void _tickTimer() {
    if (!mounted || _timeLeft <= 0) {
      return;
    }

    setState(() {
      _timeLeft -= 1;
    });

    if (_timeLeft == 300 && !_warnedFiveMinutes) {
      _warnedFiveMinutes = true;
      _showTimeWarning('5 minutes remaining — start wrapping up!');
    }
    if (_timeLeft == 60 && !_warnedOneMinute) {
      _warnedOneMinute = true;
      _showTimeWarning('1 minute left — submit now!');
    }

    unawaited(_persistProgress());

    if (_timeLeft <= 0) {
      _countdownTimer?.cancel();
      unawaited(_submit(autoSubmit: true));
    }
  }

  void _showTimeWarning(String message) {
    if (!mounted) {
      return;
    }
    MockToast.info(context, message, duration: const Duration(seconds: 4));
  }

  List<MockQuestion> get _questions {
    final questions = _session?.exam.questions ?? const <MockQuestion>[];
    return [...questions]..sort((left, right) => left.position.compareTo(right.position));
  }

  MockQuestion? get _currentQuestion {
    final questions = _questions;
    if (questions.isEmpty || _currentIndex >= questions.length) {
      return null;
    }
    return questions[_currentIndex];
  }

  int get _answeredCount => _answers.length;

  int get _reviewCount => _markedForReview.values.where((flagged) => flagged).length;

  int get _durationSeconds {
    final total = (_session?.exam.durationMinutes ?? 0) * 60;
    return total > 0 ? (total - _timeLeft).clamp(0, total) : DateTime.now().difference(_startedAt).inSeconds;
  }

  bool get _isLowTime => _timeLeft <= 300 && _timeLeft > 60;

  bool get _isCriticalTime => _timeLeft <= 60 && _timeLeft > 0;

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _persistProgress() async {
    final session = _session;
    if (session == null) {
      return;
    }

    await ref.read(examSessionStoreProvider).saveSession(
          slug: widget.slug,
          attemptId: session.attemptId,
          exam: session.exam,
          answers: Map<String, int>.from(_answers),
          currentIndex: _currentIndex,
          startedAt: _startedAt,
          timeLeftSeconds: _timeLeft,
          markedForReview: Map<String, bool>.from(_markedForReview),
        );
  }

  Future<void> _updateAnswer(String questionId, int optionIndex) async {
    setState(() => _answers[questionId] = optionIndex);
    await _persistProgress();
  }

  Future<void> _toggleReview(String questionId) async {
    setState(() => _markedForReview[questionId] = !(_markedForReview[questionId] ?? false));
    await _persistProgress();
  }

  Future<void> _goToQuestion(int index) async {
    setState(() => _currentIndex = index);
    await _persistProgress();
  }

  String _submitDescription() {
    final total = _questions.length;
    final unanswered = (total - _answeredCount).clamp(0, total);
    final reviewCount = _reviewCount;

    if (unanswered > 0 || reviewCount > 0) {
      return 'You still have $unanswered unanswered question${unanswered == 1 ? '' : 's'}'
          ' and $reviewCount marked for review. Submit anyway?';
    }
    return MockVoice.submitExamDefaultDesc;
  }

  Future<bool> _confirmSubmit() async {
    return MockConfirmDialog.show(
      context,
      title: MockVoice.submitExamTitle,
      message: _submitDescription(),
      confirmLabel: MockVoice.submitExamConfirm,
      cancelLabel: MockVoice.submitExamKeepGoing,
      variant: MockConfirmDialogVariant.warning,
    );
  }

  Future<bool> _confirmExit() async {
    return MockConfirmDialog.show(
      context,
      title: MockVoice.exitExamTitle,
      message: MockVoice.exitExamDesc,
      confirmLabel: MockVoice.exitExamConfirm,
      cancelLabel: MockVoice.exitExamStay,
      variant: MockConfirmDialogVariant.warning,
    );
  }

  Future<void> _requestSubmit() async {
    if (_isSubmitting) {
      return;
    }
    await _submit();
  }

  Future<void> _submit({bool autoSubmit = false}) async {
    final session = _session;
    if (session == null || _isSubmitting) {
      return;
    }

    if (!autoSubmit) {
      final confirmed = await _confirmSubmit();
      if (!confirmed) {
        return;
      }
    }

    setState(() => _isSubmitting = true);
    _countdownTimer?.cancel();
    final durationSeconds = _durationSeconds;
    final payload = Map<String, int>.from(_answers);
    final connectivity = await ref.read(connectivityServiceProvider).currentStatus();

    try {
      if (!connectivity.isOnline) {
        await _queueOfflineSubmit(session, payload, durationSeconds);
        return;
      }

      final result = await ref.read(mockPortalRepositoryProvider).submitAttempt(
            attemptId: session.attemptId,
            answers: payload,
            durationSeconds: durationSeconds,
          );
      await ref.read(examSessionStoreProvider).clearActiveSession();
      ref.invalidate(attemptsProvider);
      if (!mounted) {
        return;
      }
      context.go('/results/${result.id}');
      MockToast.success(
        context,
        autoSubmit ? 'Time up — submitted · ${result.percentScore}%' : 'Submitted · ${result.percentScore}%',
      );
    } on ApiException catch (error) {
      if (_shouldQueueOffline(error, connectivity.isOnline)) {
        await _queueOfflineSubmit(session, payload, durationSeconds);
        return;
      }
      if (mounted) {
        MockToast.error(context, error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  bool _shouldQueueOffline(ApiException error, bool isOnline) {
    if (!isOnline) {
      return true;
    }
    final message = error.message.toLowerCase();
    return message.contains('network') || message.contains('connection') || message.contains('timeout');
  }

  Future<void> _queueOfflineSubmit(
    StartAttemptResponse session,
    Map<String, int> payload,
    int durationSeconds,
  ) async {
    final pending = PendingSubmit(
      id: session.attemptId,
      attemptId: session.attemptId,
      examSlug: widget.slug,
      examTitle: session.exam.title,
      answers: payload,
      durationSeconds: durationSeconds,
      queuedAt: DateTime.now(),
    );
    await ref.read(pendingSubmitQueueProvider).enqueue(pending);
    await ref.read(examSessionStoreProvider).clearActiveSession();
    if (!mounted) {
      return;
    }
    context.go('/dashboard');
    MockToast.info(context, 'Saved offline — will sync when you reconnect');
  }

  Future<void> _openQuestionPalette() async {
    final total = _questions.length;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.page),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Question map', style: context.sectionTitle),
                const SizedBox(height: 8),
                Text(
                  '$_answeredCount of $total answered · $_reviewCount flagged',
                  style: context.caption,
                ),
                const SizedBox(height: AppSpacing.section),
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: total,
                    itemBuilder: (context, index) {
                      final question = _questions[index];
                      final isCurrent = index == _currentIndex;
                      final isAnswered = _answers.containsKey(question.id);
                      final isFlagged = _markedForReview[question.id] ?? false;

                      Color background;
                      Color foreground;
                      if (isCurrent) {
                        background = context.appPrimarySoft;
                        foreground = AppColors.primary;
                      } else if (isFlagged) {
                        background = context.appWarningSoft;
                        foreground = AppColors.warning;
                      } else if (isAnswered) {
                        background = context.appSuccessSoft;
                        foreground = AppColors.success;
                      } else {
                        background = context.appNeutralSoft;
                        foreground = context.appTextSecondary;
                      }

                      return OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: background,
                          foregroundColor: foreground,
                          side: BorderSide(
                            color: isCurrent ? AppColors.primary : context.appBorder,
                            width: isCurrent ? 1.5 : 1,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          unawaited(_goToQuestion(index));
                        },
                        child: Text('${index + 1}', style: context.caption.copyWith(fontWeight: FontWeight.w700)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: MockLoadingView(message: 'Starting exam…'));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: const MockBackButton(),
        ),
        body: MockErrorView(message: _error!, onRetry: _loadSession),
      );
    }

    final question = _currentQuestion;
    final total = _questions.length;
    final progress = total == 0 ? 0.0 : _answeredCount / total;
    final timerBackground = _isCriticalTime
        ? context.appErrorSoft
        : _isLowTime
            ? context.appWarningSoft
            : context.appNeutralSoft;
    final timerColor = _isCriticalTime
        ? AppColors.error
        : _isLowTime
            ? AppColors.warning
            : context.appTextSecondary;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final shouldExit = await _confirmExit();
        if (shouldExit && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: const MockBackButton(),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _session?.exam.title ?? 'Exam',
                style: context.cardTitle.copyWith(fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Question ${_currentIndex + 1} of $total',
                style: context.caption,
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0.5),
            child: Container(height: 0.5, color: context.appBorder),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: timerBackground,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: context.appBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 16, color: timerColor),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_timeLeft),
                    style: context.caption.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontWeight: FontWeight.w700,
                      color: timerColor,
                    ),
                  ),
                ],
              ),
            ),
            if (_isOfflineSession)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.wifi_off_outlined,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            IconButton(
              tooltip: 'Question map',
              onPressed: _openQuestionPalette,
              icon: const Icon(Icons.grid_view_rounded),
            ),
            TextButton(
              onPressed: _isSubmitting ? null : _requestSubmit,
              child: _isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit'),
            ),
          ],
        ),
        body: question == null
            ? const MockEmptyState(title: 'No questions', message: 'This exam has no questions yet.')
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.page),
                children: [
                  if (_isOfflineSession) ...[
                    MockInlineNotice.info(message: 'Offline mode — answers stay on this device until you reconnect.'),
                    const SizedBox(height: AppSpacing.section),
                  ],
                  if (_showRecoveryNotice) ...[
                    MockInlineNotice.info(
                      message: 'Saved session restored. You can continue from where you stopped.',
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(() => _showRecoveryNotice = false),
                        child: const Text('Dismiss'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.section),
                  ],
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(999),
                    backgroundColor: context.appNeutralSoft,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$_answeredCount of $total answered · $_reviewCount flagged',
                    style: context.caption,
                  ),
                  const SizedBox(height: AppSpacing.page),
                  if (question.hasQuestionGroup) ...[
                    MockCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (question.questionGroupTitle?.isNotEmpty ?? false)
                            Text(question.questionGroupTitle!, style: context.cardTitle),
                          if (question.questionGroupText?.isNotEmpty ?? false) ...[
                            if (question.questionGroupTitle?.isNotEmpty ?? false) const SizedBox(height: 8),
                            MockRichContent(
                              content: question.questionGroupText,
                              format: question.contentFormat,
                            ),
                          ],
                          if (question.questionGroupInstructions?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 8),
                            MockRichContent(
                              content: question.questionGroupInstructions,
                              format: question.contentFormat,
                              style: context.bodySecondary.copyWith(fontSize: 14),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (question.instructions?.isNotEmpty ?? false) ...[
                    MockCard(
                      child: MockRichContent(
                        content: question.instructions,
                        format: question.contentFormat,
                        style: context.bodySecondary.copyWith(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  MockCard(
                    child: MockRichContent(
                      content: question.questionText,
                      format: question.contentFormat,
                      style: context.cardTitle.copyWith(fontSize: 16, height: 1.45),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(question.options.length, (index) {
                    final selected = _answers[question.id] == index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          backgroundColor: selected ? context.appPrimarySoft : context.colors.surface,
                          side: BorderSide(
                            color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                          ),
                        ),
                        onPressed: () => _updateAnswer(question.id, index),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: MockRichContent(
                            content: question.options[index],
                            format: question.contentFormat,
                            inline: true,
                            style: context.body.copyWith(fontSize: 15),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _toggleReview(question.id),
                    icon: Icon(
                      (_markedForReview[question.id] ?? false) ? Icons.bookmark : Icons.bookmark_outline,
                      size: 18,
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: (_markedForReview[question.id] ?? false)
                          ? context.appWarningSoft
                          : context.colors.surface,
                      foregroundColor: (_markedForReview[question.id] ?? false)
                          ? AppColors.warning
                          : context.appTextSecondary,
                    ),
                    label: Text(
                      (_markedForReview[question.id] ?? false) ? 'Flagged for review' : 'Flag for review',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: MockSecondaryButton(
                          label: 'Previous',
                          onPressed: _currentIndex == 0 ? null : () => _goToQuestion(_currentIndex - 1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MockPrimaryButton(
                          label: _currentIndex >= total - 1 ? 'Review & submit' : 'Next',
                          onPressed: _currentIndex >= total - 1 ? _requestSubmit : () => _goToQuestion(_currentIndex + 1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
