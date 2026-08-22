import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
import 'package:mock_mobile/core/theme/theme_context.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/utils/subject_track.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/auth/providers/auth_providers.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';
import 'package:mock_mobile/features/onboarding/presentation/widgets/onboarding_widgets.dart';
import 'package:mock_mobile/features/profile/data/profile_repository.dart';
import 'package:mock_mobile/shared/models/mock_exam.dart';

class InterestOnboardingScreen extends ConsumerStatefulWidget {
  const InterestOnboardingScreen({super.key});

  @override
  ConsumerState<InterestOnboardingScreen> createState() => _InterestOnboardingScreenState();
}

class _InterestOnboardingScreenState extends ConsumerState<InterestOnboardingScreen> {
  var _step = 1;
  String? _selectedExamTypeSlug;
  MockSubjectTrack? _selectedTrack;
  final _selectedSubjectIds = <String>[];
  final _targetScoreController = TextEditingController();
  var _prepYear = DateTime.now().year;
  var _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _targetScoreController.dispose();
    super.dispose();
  }

  List<MockSubject> _subjectsFor(MockExamType? type) {
    final subjects = [...?type?.subjects];
    subjects.sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
    return subjects;
  }

  Future<void> _finish({required bool includeOptional}) async {
    if (_selectedExamTypeSlug == null || _selectedTrack == null || _selectedSubjectIds.isEmpty) {
      setState(() => _error = 'Pick your exam, track, and at least one subject.');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final payload = <String, dynamic>{
        'primaryExamTypeSlug': _selectedExamTypeSlug,
        'subjectTrack': subjectTrackToApi(_selectedTrack!),
        'subjectIds': _selectedSubjectIds,
      };
      if (includeOptional) {
        payload['prepYear'] = _prepYear;
        final target = int.tryParse(_targetScoreController.text.trim());
        payload['targetScore'] = target;
      }
      await ref.read(profileRepositoryProvider).savePreferences(payload);
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (mounted) context.go('/dashboard');
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _goToStep(int step) {
    setState(() => _step = step);
  }

  String get _stepTitle {
    return switch (_step) {
      1 => 'Which exam are you preparing for?',
      2 => 'Which subjects do you want to practice?',
      _ => 'Almost done!',
    };
  }

  String get _stepSubtitle {
    return switch (_step) {
      1 => 'Pick the exam you are preparing for.',
      2 => 'Choose your track and subject combo.',
      _ => 'Optional goals for your dashboard.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final examTypesAsync = ref.watch(examTypesProvider);
    final selectedType = examTypesAsync.maybeWhen(
      data: (types) => types.where((type) => type.slug == _selectedExamTypeSlug).firstOrNull,
      orElse: () => null,
    );
    final subjects = _subjectsFor(selectedType);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const MockBackButton(),
        title: const Text('Exam setup'),
      ),
      body: examTypesAsync.when(
        loading: () => const MockLoadingView(message: 'Loading exam types…'),
        error: (error, _) => MockErrorView(message: error.toString(), onRetry: () => ref.invalidate(examTypesProvider)),
        data: (examTypes) => ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            OnboardingStepProgress(step: _step, totalSteps: 3),
            const SizedBox(height: AppSpacing.page),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: Text(
                _stepTitle,
                key: ValueKey<String>('title-$_step'),
                style: context.pageTitle,
              ),
            ),
            const SizedBox(height: AppSpacing.item),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: Text(
                _stepSubtitle,
                key: ValueKey<String>('subtitle-$_step'),
                style: context.pageSubtitle,
              ),
            ),
            const SizedBox(height: AppSpacing.page),
            if (_error != null) ...[
              MockInlineNotice.error(message: _error!),
              const SizedBox(height: AppSpacing.section),
            ],
            OnboardingStepTransition(
              step: _step,
              child: _buildStepContent(examTypes, subjects),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(List<MockExamType> examTypes, List<MockSubject> subjects) {
    if (_step == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...examTypes.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.section),
                  child: OnboardingFadeInList(
                    index: entry.key,
                    child: MockCard(
                      child: InkWell(
                        onTap: () => setState(() {
                          _selectedExamTypeSlug = entry.value.slug;
                          _selectedTrack = null;
                          _selectedSubjectIds.clear();
                          _step = 2;
                        }),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.value.title, style: context.cardTitle),
                            if (entry.value.description?.isNotEmpty == true) ...[
                              const SizedBox(height: AppSpacing.item),
                              Text(entry.value.description!, style: context.bodySecondary),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        ],
      );
    }

    if (_step == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextButton(onPressed: () => _goToStep(1), child: const Text('← Change exam')),
          const SizedBox(height: AppSpacing.section),
          const MockSectionTitle(title: 'Pick your track'),
          const SizedBox(height: AppSpacing.item),
          ...mockSubjectTrackOptions.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.item),
                  child: OnboardingFadeInList(
                    index: entry.key,
                    child: _SelectableTile(
                      title: entry.value.label,
                      subtitle: entry.value.description,
                      selected: _selectedTrack == entry.value.track,
                      onTap: () {
                        setState(() {
                          _selectedTrack = entry.value.track;
                          _selectedSubjectIds
                            ..clear()
                            ..addAll(resolveSubjectIdsForTrack(
                              examTypeSlug: _selectedExamTypeSlug ?? '',
                              track: entry.value.track,
                              subjects: subjects.map((s) => (id: s.id, slug: s.slug)).toList(),
                            ));
                        });
                      },
                    ),
                  ),
                ),
              ),
          if (_selectedTrack != null) ...[
            const SizedBox(height: AppSpacing.page),
            const MockSectionTitle(title: 'Your subject combo'),
            const SizedBox(height: AppSpacing.item),
            ...subjects.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.item),
                    child: OnboardingFadeInList(
                      index: entry.key,
                      child: _SelectableTile(
                        title: entry.value.name,
                        selected: _selectedSubjectIds.contains(entry.value.id),
                        onTap: () => setState(() {
                          if (_selectedSubjectIds.contains(entry.value.id)) {
                            _selectedSubjectIds.remove(entry.value.id);
                          } else {
                            _selectedSubjectIds.add(entry.value.id);
                          }
                        }),
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: AppSpacing.page),
            MockPrimaryButton(
              label: 'Continue',
              onPressed: _selectedSubjectIds.isEmpty ? null : () => _goToStep(3),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton(onPressed: () => _goToStep(2), child: const Text('← Back to subjects')),
        const SizedBox(height: AppSpacing.section),
        OnboardingFadeInList(
          index: 0,
          child: DropdownButtonFormField<int>(
            value: _prepYear,
            decoration: const InputDecoration(labelText: 'When are you sitting the exam?'),
            items: prepYearOptions()
                .map((year) => DropdownMenuItem(value: year, child: Text('$year')))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _prepYear = value);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        OnboardingFadeInList(
          index: 1,
          child: MockTextField(
            label: 'Target score (optional)',
            controller: _targetScoreController,
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(height: AppSpacing.page),
        MockSplitActionRow(
          start: MockSecondaryButton(
            label: _isSaving ? 'Saving…' : 'Skip for now',
            onPressed: _isSaving ? null : () => _finish(includeOptional: false),
            expand: true,
          ),
          end: MockPrimaryButton(
            label: _isSaving ? 'Saving…' : 'Start practicing',
            isLoading: _isSaving,
            onPressed: () => _finish(includeOptional: true),
            expand: true,
          ),
        ),
      ],
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? context.appPrimarySoft : context.colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: selected ? AppColors.primary : context.appBorder),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: context.isDarkMode ? 0.18 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.section),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: selected ? AppColors.primary : context.appBorder,
                      width: 1.5,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: AppSpacing.section),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.cardTitle),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle!, style: context.caption),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
