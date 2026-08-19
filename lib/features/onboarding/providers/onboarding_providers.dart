import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/core/storage/app_prefs_storage.dart';

class OnboardingState extends Equatable {
  const OnboardingState({
    required this.isLoading,
    required this.hasSeenOnboarding,
  });

  const OnboardingState.loading() : this(isLoading: true, hasSeenOnboarding: false);

  final bool isLoading;
  final bool hasSeenOnboarding;

  @override
  List<Object?> get props => [isLoading, hasSeenOnboarding];
}

class OnboardingController extends Notifier<OnboardingState> {
  late AppPrefsStorage _storage;

  @override
  OnboardingState build() {
    _storage = ref.read(appPrefsStorageProvider);
    _load();
    return const OnboardingState.loading();
  }

  Future<void> _load() async {
    final seen = await _storage.hasSeenOnboarding();
    state = OnboardingState(isLoading: false, hasSeenOnboarding: seen);
  }

  Future<void> completeOnboarding() async {
    await _storage.setOnboardingSeen();
    state = const OnboardingState(isLoading: false, hasSeenOnboarding: true);
  }
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(OnboardingController.new);
