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
            Text(
              _step == 1
                  ? 'Which exam are you preparing for?'
                  : _step == 2
                      ? 'Which subjects do you want to practice?'
                      : 'Almost done!',
              style: context.pageTitle,
            ),
            const SizedBox(height: AppSpacing.item),
            Text(
              _step == 1
                  ? 'Step 1 of 3 — pick the exam you are preparing for.'
                  : _step == 2
                      ? 'Step 2 of 3 — pick your track and subject combo.'
                      : 'Step 3 of 3 — optional goals for your dashboard.',
              style: context.pageSubtitle,
            ),
            const SizedBox(height: AppSpacing.page),
            if (_error != null) ...[
              MockInlineNotice.error(message: _error!),
              const SizedBox(height: AppSpacing.section),
            ],
            if (_step == 1)
              ...examTypes.map(
                (type) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.section),
                  child: MockCard(
                    child: InkWell(
                      onTap: () => setState(() {
                        _selectedExamTypeSlug = type.slug;
                        _selectedTrack = null;
                        _selectedSubjectIds.clear();
                        _step = 2;
                      }),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(type.title, style: context.cardTitle),
                          if (type.description?.isNotEmpty == true) ...[
                            const SizedBox(height: AppSpacing.item),
                            Text(type.description!, style: context.bodySecondary),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_step == 2) ...[
              TextButton(onPressed: () => setState(() => _step = 1), child: const Text('← Change exam')),
              const SizedBox(height: AppSpacing.section),
              const MockSectionTitle(title: 'Pick your track'),
              const SizedBox(height: AppSpacing.item),
              ...mockSubjectTrackOptions.map(
                (option) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.item),
                  child: _SelectableTile(
                    title: option.label,
                    subtitle: option.description,
                    selected: _selectedTrack == option.track,
                    onTap: () {
                      setState(() {
                        _selectedTrack = option.track;
                        _selectedSubjectIds
                          ..clear()
                          ..addAll(resolveSubjectIdsForTrack(
                            examTypeSlug: _selectedExamTypeSlug ?? '',
                            track: option.track,
                            subjects: subjects.map((s) => (id: s.id, slug: s.slug)).toList(),
                          ));
                      });
                    },
                  ),
                ),
              ),
              if (_selectedTrack != null) ...[
                const SizedBox(height: AppSpacing.page),
                const MockSectionTitle(title: 'Your subject combo'),
                const SizedBox(height: AppSpacing.item),
                ...subjects.map(
                  (subject) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.item),
                    child: _SelectableTile(
                      title: subject.name,
                      selected: _selectedSubjectIds.contains(subject.id),
                      onTap: () => setState(() {
                        if (_selectedSubjectIds.contains(subject.id)) {
                          _selectedSubjectIds.remove(subject.id);
                        } else {
                          _selectedSubjectIds.add(subject.id);
                        }
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.page),
                MockPrimaryButton(
                  label: 'Continue',
                  onPressed: _selectedSubjectIds.isEmpty ? null : () => setState(() => _step = 3),
                ),
              ],
            ],
            if (_step == 3) ...[
              TextButton(onPressed: () => setState(() => _step = 2), child: const Text('← Back to subjects')),
              const SizedBox(height: AppSpacing.section),
              DropdownButtonFormField<int>(
                value: _prepYear,
                decoration: const InputDecoration(labelText: 'When are you sitting the exam?'),
                items: prepYearOptions()
                    .map((year) => DropdownMenuItem(value: year, child: Text('$year')))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _prepYear = value);
                },
              ),
              const SizedBox(height: AppSpacing.section),
              MockTextField(
                label: 'Target score (optional)',
                controller: _targetScoreController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.page),
              MockSecondaryButton(
                label: _isSaving ? 'Saving…' : 'Skip for now',
                onPressed: _isSaving ? null : () => _finish(includeOptional: false),
              ),
              const SizedBox(height: AppSpacing.item),
              MockPrimaryButton(
                label: _isSaving ? 'Saving…' : 'Start practicing',
                isLoading: _isSaving,
                onPressed: () => _finish(includeOptional: true),
              ),
            ],
          ],
        ),
      ),
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
    return Material(
      color: selected ? context.appPrimarySoft : context.colors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.section),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: selected ? AppColors.primary : context.appBorder),
          ),
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
