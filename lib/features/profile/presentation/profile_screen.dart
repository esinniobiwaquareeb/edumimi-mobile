import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mock_mobile/core/constants/mock_voice.dart';
import 'package:mock_mobile/core/theme/app_icons.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/core/storage/app_prefs_storage.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
import 'package:mock_mobile/core/theme/app_spacing.dart';
import 'package:mock_mobile/core/theme/app_text.dart';
import 'package:mock_mobile/core/theme/theme_provider.dart';
import 'package:mock_mobile/core/theme/theme_context.dart';
import 'package:mock_mobile/core/utils/subject_track.dart';
import 'package:mock_mobile/core/utils/mock_preparation_profile.dart';
import 'package:mock_mobile/core/utils/share_utils.dart';
import 'package:mock_mobile/core/widgets/mock_share_button.dart';
import 'package:mock_mobile/core/widgets/mock_ui.dart';
import 'package:mock_mobile/features/auth/providers/auth_providers.dart';
import 'package:mock_mobile/features/mock/data/mock_portal_repository.dart';
import 'package:mock_mobile/features/payments/data/payment_repository.dart';
import 'package:mock_mobile/features/profile/data/profile_repository.dart';
import 'package:mock_mobile/shared/models/mock_engagement.dart';
import 'package:mock_mobile/shared/models/mock_user.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final engagementAsync = ref.watch(engagementProvider);
    final themeMode = ref.watch(themeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const MockBackButton(),
        title: const Text('My profile'),
        bottom: MockFilledTabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Personal'),
            Tab(text: 'Exam setup'),
            Tab(text: 'Referral'),
          ],
        ),
      ),
      body: user == null
          ? const MockLoadingView()
          : TabBarView(
              controller: _tabController,
              children: [
                _PersonalTab(
                  user: user,
                  themeMode: themeMode,
                  onThemeChanged: (mode) =>
                      ref.read(themeControllerProvider.notifier).setMode(mode),
                  onUserUpdated: () =>
                      ref.read(authControllerProvider.notifier).refreshUser(),
                ),
                _PrepProfileTab(
                  user: user,
                  onSaved: () =>
                      ref.read(authControllerProvider.notifier).refreshUser(),
                ),
                _ReferralTab(engagementAsync: engagementAsync),
              ],
            ),
    );
  }
}

class _PersonalTab extends ConsumerStatefulWidget {
  const _PersonalTab({
    required this.user,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onUserUpdated,
  });

  final MockUser user;
  final ThemeMode themeMode;
  final ValueChanged<AppThemeMode> onThemeChanged;
  final VoidCallback onUserUpdated;

  @override
  ConsumerState<_PersonalTab> createState() => _PersonalTabState();
}

class _PersonalTabState extends ConsumerState<_PersonalTab> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _bulkLicenseController;
  var _isSavingProfile = false;
  var _isChangingPassword = false;
  var _isUploadingAvatar = false;
  var _isRedeemingLicense = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _bulkLicenseController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _bulkLicenseController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSavingProfile = true;
      _error = null;
    });
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(
            fullName: _nameController.text,
            phone: _phoneController.text,
          );
      widget.onUserUpdated();
      if (mounted) MockToast.success(context, 'Profile updated');
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text.length < 8) {
      setState(() => _error = 'New password must be at least 8 characters.');
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _isChangingPassword = true;
      _error = null;
    });
    try {
      await ref
          .read(profileRepositoryProvider)
          .changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      if (mounted) MockToast.success(context, 'Password updated');
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() => _isUploadingAvatar = true);
    try {
      await ref.read(profileRepositoryProvider).uploadAvatar(file.path);
      widget.onUserUpdated();
      if (mounted) MockToast.success(context, 'Profile photo updated');
    } on ApiException catch (error) {
      if (mounted) MockToast.error(context, error.message);
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _removeAvatar() async {
    final confirmed = await MockConfirmDialog.show(
      context,
      title: MockVoice.removeAvatarTitle,
      message: MockVoice.removeAvatarDesc,
      confirmLabel: MockVoice.removeAvatarConfirm,
      variant: MockConfirmDialogVariant.danger,
      isDestructiveConfirm: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isUploadingAvatar = true);
    try {
      await ref.read(profileRepositoryProvider).removeAvatar();
      widget.onUserUpdated();
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _resendVerification() async {
    try {
      await ref
          .read(profileRepositoryProvider)
          .resendVerification(widget.user.email);
      if (mounted) {
        MockToast.success(context, 'Verification email sent');
      }
    } on ApiException catch (error) {
      if (mounted) MockToast.error(context, error.message);
    }
  }

  Future<void> _shareParentLink(Rect sharePositionOrigin) async {
    try {
      final link = await ref
          .read(profileRepositoryProvider)
          .fetchParentShareLink();
      await shareParentProgressLink(
        link.shareUrl,
        sharePositionOrigin: sharePositionOrigin,
      );
    } on ApiException catch (error) {
      if (mounted) MockToast.error(context, error.message);
    }
  }

  Future<void> _redeemBulkLicense() async {
    final code = _bulkLicenseController.text.trim();
    if (code.isEmpty) return;

    final confirmed = await MockConfirmDialog.show(
      context,
      title: MockVoice.redeemLicenseTitle,
      message: MockVoice.redeemLicenseDesc,
      confirmLabel: MockVoice.redeemLicenseConfirm,
      variant: MockConfirmDialogVariant.info,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isRedeemingLicense = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .redeemBulkLicense(
            code,
            platform: ref.read(paymentRepositoryProvider).platform,
          );
      _bulkLicenseController.clear();
      if (mounted) {
        MockToast.success(context, 'License redeemed');
      }
    } on ApiException catch (error) {
      if (mounted) MockToast.error(context, error.message);
    } finally {
      if (mounted) setState(() => _isRedeemingLicense = false);
    }
  }

  AppThemeMode _currentThemeMode() {
    return switch (widget.themeMode) {
      ThemeMode.light => AppThemeMode.light,
      ThemeMode.dark => AppThemeMode.dark,
      ThemeMode.system => AppThemeMode.system,
    };
  }

  @override
  Widget build(BuildContext context) {
    final commerceSettings = ref.watch(commerceSettingsProvider).valueOrNull;
    final verified =
        widget.user.isVerified == true ||
        widget.user.mockProfile?.isVerified == true;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.page),
      children: [
        MockCard(
          child: Row(
            children: [
              Stack(
                children: [
                  widget.user.avatarUrl?.isNotEmpty == true
                      ? CircleAvatar(
                          radius: 28,
                          backgroundImage: NetworkImage(widget.user.avatarUrl!),
                        )
                      : MockUserAvatar(
                          initials: widget.user.initials,
                          size: 56,
                        ),
                  if (_isUploadingAvatar)
                    const Positioned.fill(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.section),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.user.displayName, style: context.sectionTitle),
                    Text(widget.user.email, style: context.bodySecondary),
                    if (verified)
                      const Padding(
                        padding: EdgeInsets.only(top: AppSpacing.item),
                        child: MockChip(
                          label: 'Verified',
                          tone: MockChipTone.success,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        Row(
          children: [
            Expanded(
              child: MockSecondaryButton(
                label: 'Change photo',
                onPressed: _isUploadingAvatar ? null : _pickAvatar,
              ),
            ),
            const SizedBox(width: AppSpacing.item),
            if (widget.user.avatarUrl?.isNotEmpty == true)
              Expanded(
                child: MockDestructiveButton(
                  label: 'Remove',
                  onPressed: _isUploadingAvatar ? null : _removeAvatar,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.page),
        if (!verified) ...[
          MockCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email verification required', style: context.cardTitle),
                const SizedBox(height: AppSpacing.item),
                Text(
                  'A confirmation link was sent to ${widget.user.email}.',
                  style: context.bodySecondary,
                ),
                const SizedBox(height: AppSpacing.section),
                MockSecondaryButton(
                  label: 'Resend verification email',
                  onPressed: _resendVerification,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.page),
        ],
        if (_error != null) ...[
          MockInlineNotice.error(message: _error!),
          const SizedBox(height: AppSpacing.section),
        ],
        MockCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Personal details', style: context.sectionTitle),
              const SizedBox(height: AppSpacing.section),
              MockTextField(label: 'Full name', controller: _nameController),
              const SizedBox(height: AppSpacing.section),
              MockTextField(
                label: 'Phone (optional)',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.section),
              TextFormField(
                initialValue: widget.user.email,
                readOnly: true,
                enabled: false,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: AppSpacing.section),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 220,
                  child: MockPrimaryButton(
                    label: _isSavingProfile ? 'Saving…' : 'Save changes',
                    isLoading: _isSavingProfile,
                    onPressed: _saveProfile,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.page),
        MockCard(
          child: _ProfileExpansion(
            icon: Icons.lock_outline_rounded,
            title: 'Password',
            subtitle: 'Change the password used to sign in.',
            child: Column(
              children: [
                MockTextField(
                  label: 'Current password',
                  controller: _currentPasswordController,
                  obscurable: true,
                ),
                const SizedBox(height: AppSpacing.section),
                MockTextField(
                  label: 'New password',
                  controller: _newPasswordController,
                  obscurable: true,
                ),
                const SizedBox(height: AppSpacing.section),
                MockTextField(
                  label: 'Confirm new password',
                  controller: _confirmPasswordController,
                  obscurable: true,
                ),
                const SizedBox(height: AppSpacing.section),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 220,
                    child: MockPrimaryButton(
                      label: _isChangingPassword
                          ? 'Updating…'
                          : 'Update password',
                      isLoading: _isChangingPassword,
                      onPressed: _changePassword,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.page),
        MockCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Appearance', style: context.sectionTitle),
              const SizedBox(height: AppSpacing.section),
              MockSegmentedControl<AppThemeMode>(
                segments: AppThemeMode.values,
                selected: _currentThemeMode(),
                onChanged: widget.onThemeChanged,
                labelBuilder: (mode) => switch (mode) {
                  AppThemeMode.light => 'Light',
                  AppThemeMode.dark => 'Dark',
                  AppThemeMode.system => 'System',
                },
              ),
              const SizedBox(height: AppSpacing.section),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.page),
        MockCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileExpansion(
                icon: Icons.ios_share_outlined,
                title: 'Share progress',
                subtitle:
                    'Send a read-only progress link to a parent or coach.',
                child: MockShareButton(
                  label: 'Share parent link',
                  onShare: _shareParentLink,
                ),
              ),
              const Divider(),
              if (commerceSettings?.bulkLicensesEnabled ?? true) ...[
                _ProfileExpansion(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Redeem school licence',
                  subtitle: 'Enter a code provided by your school.',
                  child: Column(
                    children: [
                      MockTextField(
                        label: 'Licence code',
                        controller: _bulkLicenseController,
                      ),
                      const SizedBox(height: AppSpacing.section),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 200,
                          child: MockPrimaryButton(
                            label: _isRedeemingLicense
                                ? 'Redeeming…'
                                : 'Redeem code',
                            isLoading: _isRedeemingLicense,
                            onPressed: _redeemBulkLicense,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.page),
        if (commerceSettings?.paymentsEnabled ?? true)
          MockPrimaryButton(
            label: 'Browse packages',
            onPressed: () => context.push('/packages'),
          ),
        const SizedBox(height: AppSpacing.section),
        MockDestructiveButton(
          label: MockVoice.logOut,
          onPressed: () async {
            final confirmed = await MockConfirmDialog.show(
              context,
              title: MockVoice.logOutTitle,
              message: MockVoice.logOutDesc,
              confirmLabel: MockVoice.logOut,
              variant: MockConfirmDialogVariant.danger,
              isDestructiveConfirm: true,
              icon: AppIcons.logout,
            );
            if (!confirmed || !context.mounted) return;
            await ref.read(authControllerProvider.notifier).logout();
            if (context.mounted) context.go('/login');
          },
        ),
        const SizedBox(height: AppSpacing.item),
        TextButton(
          onPressed: () async {
            final confirmed = await MockConfirmDialog.show(
              context,
              title: 'Delete Account',
              message:
                  'Are you sure you want to permanently delete your account? This action cannot be undone and you will lose all your progress and purchases.',
              confirmLabel: 'Delete Account',
              variant: MockConfirmDialogVariant.danger,
              isDestructiveConfirm: true,
              icon: AppIcons.logout,
            );
            if (!confirmed || !context.mounted) return;
            try {
              await ref.read(authControllerProvider.notifier).deleteAccount();
              if (context.mounted) context.go('/login');
            } catch (e) {
              if (context.mounted) {
                MockToast.show(
                  context,
                  'Failed to delete account',
                  tone: MockToastTone.error,
                );
              }
            }
          },
          child: Text(
            'Delete Account',
            style: context.body.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileExpansion extends StatelessWidget {
  const _ProfileExpansion({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: AppSpacing.item),
        leading: Icon(icon, color: context.appTextSecondary),
        title: Text(title, style: context.cardTitle),
        subtitle: Text(subtitle, style: context.caption),
        children: [child],
      ),
    );
  }
}

class _PrepProfileTab extends ConsumerStatefulWidget {
  const _PrepProfileTab({required this.user, required this.onSaved});

  final MockUser user;
  final VoidCallback onSaved;

  @override
  ConsumerState<_PrepProfileTab> createState() => _PrepProfileTabState();
}

class _PrepProfileTabState extends ConsumerState<_PrepProfileTab> {
  String? _selectedExamTypeSlug;
  MockSubjectTrack? _selectedTrack;
  final _selectedSubjectIds = <String>[];
  int? _paperYearFrom;
  int? _paperYearTo;
  int? _prepYear;
  var _practiceTimerEnabled = true;
  final _targetScoreController = TextEditingController();
  var _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final interests = widget.user.mockProfile?.interests;
    _selectedExamTypeSlug = interests?.primaryExamTypeSlug;
    _selectedTrack = normalizeSubjectTrack(interests?.subjectTrack);
    _selectedSubjectIds.addAll(interests?.subjectIds ?? const []);
    _paperYearFrom = interests?.paperYearFrom;
    _paperYearTo = interests?.paperYearTo;
    _prepYear = interests?.prepYear ?? DateTime.now().year;
    _practiceTimerEnabled = resolvePracticeTimerEnabled(
      interests?.practiceTimerEnabled,
    );
    if (interests?.targetScore != null) {
      _targetScoreController.text = '${interests!.targetScore}';
    }
  }

  @override
  void dispose() {
    _targetScoreController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedExamTypeSlug == null || _selectedTrack == null) {
      setState(() => _error = 'Pick your exam and track.');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await ref.read(profileRepositoryProvider).savePreferences({
        'primaryExamTypeSlug': _selectedExamTypeSlug,
        'subjectTrack': subjectTrackToApi(_selectedTrack!),
        'subjectIds': _selectedSubjectIds,
        'paperYearFrom': _paperYearFrom,
        'paperYearTo': _paperYearTo,
        'prepYear': _prepYear,
        'targetScore': int.tryParse(_targetScoreController.text.trim()),
        'practiceTimerEnabled': _practiceTimerEnabled,
      });
      widget.onSaved();
      if (mounted) MockToast.success(context, 'Prep profile saved');
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
      data: (types) =>
          types.where((type) => type.slug == _selectedExamTypeSlug).firstOrNull,
      orElse: () => null,
    );
    final subjects = [...?selectedType?.subjects]
      ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));

    return examTypesAsync.when(
      loading: () => const MockLoadingView(message: 'Loading exam types…'),
      error: (error, _) => MockErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(examTypesProvider),
      ),
      data: (examTypes) => ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          Text('Exam setup', style: context.pageTitle),
          const SizedBox(height: AppSpacing.item),
          Text(
            'Choose your exam, track, paper years, and goals.',
            style: context.pageSubtitle,
          ),
          const SizedBox(height: AppSpacing.page),
          if (_error != null) ...[
            MockInlineNotice.error(message: _error!),
            const SizedBox(height: AppSpacing.section),
          ],
          const MockSectionTitle(title: 'Your exam'),
          const SizedBox(height: AppSpacing.section),
          ...examTypes.map(
            (type) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.item),
              child: _SelectableTile(
                title: type.title,
                selected: _selectedExamTypeSlug == type.slug,
                onTap: () => setState(() {
                  _selectedExamTypeSlug = type.slug;
                  _selectedTrack = null;
                  _selectedSubjectIds.clear();
                }),
              ),
            ),
          ),
          if (_selectedExamTypeSlug != null) ...[
            const MockSectionTitle(title: 'Your track'),
            const SizedBox(height: AppSpacing.section),
            ...mockSubjectTrackOptions.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.item),
                child: _SelectableTile(
                  title: option.label,
                  subtitle: option.description,
                  selected: _selectedTrack == option.track,
                  onTap: () => setState(() {
                    _selectedTrack = option.track;
                    _selectedSubjectIds
                      ..clear()
                      ..addAll(
                        resolveSubjectIdsForTrack(
                          examTypeSlug: _selectedExamTypeSlug!,
                          track: option.track,
                          subjects: subjects
                              .map((s) => (id: s.id, slug: s.slug))
                              .toList(),
                        ),
                      );
                  }),
                ),
              ),
            ),
          ],
          if (_selectedTrack != null) ...[
            const MockSectionTitle(title: 'Your subjects'),
            const SizedBox(height: AppSpacing.section),
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
          ],
          const MockSectionTitle(title: 'Paper year focus'),
          const SizedBox(height: AppSpacing.section),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _paperYearFrom,
                  decoration: const InputDecoration(labelText: 'From year'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Not set')),
                    ...paperYearOptions().map(
                      (y) => DropdownMenuItem(value: y, child: Text('$y')),
                    ),
                  ],
                  onChanged: (value) => setState(() => _paperYearFrom = value),
                ),
              ),
              const SizedBox(width: AppSpacing.section),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _paperYearTo,
                  decoration: const InputDecoration(labelText: 'To year'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Not set')),
                    ...paperYearOptions().map(
                      (y) => DropdownMenuItem(value: y, child: Text('$y')),
                    ),
                  ],
                  onChanged: (value) => setState(() => _paperYearTo = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.page),
          const MockSectionTitle(title: 'Practice countdown timer'),
          const SizedBox(height: AppSpacing.section),
          Text(
            'Turn off for untimed mixed practice. Full mocks and past papers always use a countdown.',
            style: context.pageSubtitle,
          ),
          const SizedBox(height: AppSpacing.section),
          Row(
            children: [
              Expanded(
                child: _SelectableTile(
                  title: 'Timer on',
                  selected: _practiceTimerEnabled,
                  onTap: () => setState(() => _practiceTimerEnabled = true),
                ),
              ),
              const SizedBox(width: AppSpacing.section),
              Expanded(
                child: _SelectableTile(
                  title: 'Timer off',
                  selected: !_practiceTimerEnabled,
                  onTap: () => setState(() => _practiceTimerEnabled = false),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.page),
          DropdownButtonFormField<int>(
            value: _prepYear,
            decoration: const InputDecoration(labelText: 'Sitting year'),
            items: prepYearOptions()
                .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _prepYear = value);
            },
          ),
          const SizedBox(height: AppSpacing.section),
          MockTextField(
            label: 'Target score',
            controller: _targetScoreController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.page),
          MockPrimaryButton(
            label: _isSaving ? 'Saving…' : 'Save prep profile',
            isLoading: _isSaving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _ReferralTab extends ConsumerStatefulWidget {
  const _ReferralTab({required this.engagementAsync});

  final AsyncValue<MockEngagement> engagementAsync;

  @override
  ConsumerState<_ReferralTab> createState() => _ReferralTabState();
}

class _ReferralTabState extends ConsumerState<_ReferralTab> {
  final _applyCodeController = TextEditingController();
  final _ownCodeController = TextEditingController();
  var _isApplying = false;
  var _isUpdatingCode = false;

  @override
  void dispose() {
    _applyCodeController.dispose();
    _ownCodeController.dispose();
    super.dispose();
  }

  Future<void> _shareReferral(
    MockEngagement engagement,
    Rect sharePositionOrigin,
  ) async {
    await shareReferral(
      referralLink: engagement.referralLink,
      referralCode: engagement.referralCode ?? _ownCodeController.text,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.engagementAsync.when(
      loading: () => const MockLoadingView(message: 'Loading referral…'),
      error: (_, __) => const MockEmptyState(
        title: 'Referral unavailable',
        message: 'Try again later.',
      ),
      data: (engagement) {
        if (_ownCodeController.text.isEmpty &&
            engagement.referralCode?.isNotEmpty == true) {
          _ownCodeController.text = engagement.referralCode!;
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            Text('Invite friends', style: context.pageTitle),
            const SizedBox(height: AppSpacing.item),
            Text(
              'Share your code to earn bonus preview questions and commissions.',
              style: context.pageSubtitle,
            ),
            const SizedBox(height: AppSpacing.page),
            if (engagement.referredByCustomerId == null) ...[
              MockTextField(
                label: "Friend's referral code",
                controller: _applyCodeController,
              ),
              const SizedBox(height: AppSpacing.section),
              MockPrimaryButton(
                label: _isApplying ? 'Applying…' : 'Apply referral code',
                isLoading: _isApplying,
                onPressed: () async {
                  setState(() => _isApplying = true);
                  try {
                    await ref
                        .read(profileRepositoryProvider)
                        .applyReferralCode(_applyCodeController.text);
                    ref.invalidate(engagementProvider);
                    if (context.mounted) {
                      MockToast.success(context, 'Referral code applied');
                    }
                  } on ApiException catch (error) {
                    if (context.mounted) {
                      MockToast.error(context, error.message);
                    }
                  } finally {
                    if (mounted) setState(() => _isApplying = false);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.page),
            ] else
              MockCard(
                child: Text(
                  'A friend\'s referral code is already linked to this account.',
                  style: context.bodySecondary,
                ),
              ),
            MockCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your referral code', style: context.cardTitle),
                  const SizedBox(height: AppSpacing.section),
                  MockTextField(
                    label: 'Referral code',
                    controller: _ownCodeController,
                  ),
                  const SizedBox(height: AppSpacing.section),
                  Row(
                    children: [
                      Expanded(
                        child: MockShareButton(
                          label: 'Share invite link',
                          icon: Icons.link,
                          onShare: (origin) =>
                              _shareReferral(engagement, origin),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.item),
                      Expanded(
                        child: MockPrimaryButton(
                          label: _isUpdatingCode ? 'Saving…' : 'Update code',
                          isLoading: _isUpdatingCode,
                          onPressed: () async {
                            setState(() => _isUpdatingCode = true);
                            try {
                              await ref
                                  .read(profileRepositoryProvider)
                                  .updateReferralCode(_ownCodeController.text);
                              ref.invalidate(engagementProvider);
                              if (context.mounted) {
                                MockToast.success(
                                  context,
                                  'Referral code updated',
                                );
                              }
                            } on ApiException catch (error) {
                              if (context.mounted) {
                                MockToast.error(context, error.message);
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isUpdatingCode = false);
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
            border: Border.all(
              color: selected ? AppColors.primary : context.appBorder,
            ),
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
