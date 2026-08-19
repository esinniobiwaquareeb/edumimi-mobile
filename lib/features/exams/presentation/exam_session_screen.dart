import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/core/offline/connectivity_service.dart';
import 'package:mock_mobile/core/offline/offline_sync_service.dart';
import 'package:mock_mobile/core/offline/pending_submit_queue.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
import 'package:mock_mobile/core/utils/text_utils.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';
import 'package:mock_mobile/shared/models/mock_exam.dart';

class ExamSessionScreen extends ConsumerStatefulWidget {
  const ExamSessionScreen({super.key, required this.slug, this.attemptId});

  final String slug;
  final String? attemptId;

  @override
  ConsumerState<ExamSessionScreen> createState() => _ExamSessionScreenState();
}

class _ExamSessionScreenState extends ConsumerState<ExamSessionScreen> {
  StartAttemptResponse? _session;
  var _currentIndex = 0;
  final Map<String, int> _answers = {};
  var _isLoading = true;
  var _isSubmitting = false;
  var _isOfflineSession = false;
  String? _error;
  late DateTime _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    unawaited(_loadSession());
  }

  Future<void> _loadSession() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final response = await ref.read(mockPortalRepositoryProvider).startExam(widget.slug, sessionId: sessionId);
      await ref.read(offlinePracticeCacheProvider).cacheExamQuestions(response.exam);
      setState(() {
        _session = response;
        _isOfflineSession = false;
        _isLoading = false;
      });
      await _persistProgress();
    } on ApiException catch (error) {
      final restored = _restoreSavedSession();
      if (restored) {
        return;
      }
      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    }
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
      _currentIndex = saved.currentIndex;
      _startedAt = saved.startedAt;
      _isOfflineSession = true;
      _isLoading = false;
      _error = null;
    });
    return true;
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
        );
  }

  Future<void> _updateAnswer(String questionId, int optionIndex) async {
    setState(() => _answers[questionId] = optionIndex);
    await _persistProgress();
  }

  Future<void> _goToQuestion(int index) async {
    setState(() => _currentIndex = index);
    await _persistProgress();
  }

  Future<void> _submit() async {
    final session = _session;
    if (session == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    final durationSeconds = DateTime.now().difference(_startedAt).inSeconds;
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
      context.go('/results');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submitted · ${result.percentScore}%')),
      );
    } on ApiException catch (error) {
      if (_shouldQueueOffline(error, connectivity.isOnline)) {
        await _queueOfflineSubmit(session, payload, durationSeconds);
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved offline — will sync when you reconnect')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: MockLoadingView(message: 'Starting exam…'));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: MockErrorView(message: _error!, onRetry: _loadSession),
      );
    }

    final question = _currentQuestion;
    final total = _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentIndex + 1} of $total'),
        actions: [
          if (_isOfflineSession)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.wifi_off_outlined, color: AppColors.textSecondary),
            ),
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Submit'),
          ),
        ],
      ),
      body: question == null
          ? const MockEmptyState(title: 'No questions', message: 'This exam has no questions yet.')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_isOfflineSession)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: MockCard(
                      child: Text(
                        'Offline mode — answers stay on this device until you reconnect.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                LinearProgressIndicator(
                  value: total == 0 ? 0 : (_currentIndex + 1) / total,
                  color: AppColors.primary,
                  backgroundColor: AppColors.primarySoft,
                ),
                const SizedBox(height: 16),
                MockCard(
                  child: Text(
                    stripHtml(question.questionText),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
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
                        backgroundColor: selected ? AppColors.primarySoft : null,
                        side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
                      ),
                      onPressed: () => _updateAnswer(question.id, index),
                      child: Text(stripHtml(question.options[index])),
                    ),
                  );
                }),
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
                        onPressed: _currentIndex >= total - 1 ? _submit : () => _goToQuestion(_currentIndex + 1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
