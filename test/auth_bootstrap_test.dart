import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/core/storage/auth_storage.dart';
import 'package:mock_mobile/features/auth/data/auth_repository.dart';
import 'package:mock_mobile/features/auth/providers/auth_providers.dart';
import 'package:mock_mobile/shared/models/mock_user.dart';

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository({
    this.storedSession,
    this.fetchMeResult,
  }) : super(Dio(), AuthStorage());

  AuthSession? storedSession;
  Object? fetchMeResult;
  var clearSessionCalls = 0;
  var persistSessionCalls = 0;

  @override
  Future<AuthSession?> readStoredSession() async => storedSession;

  @override
  Future<MockUser> fetchMe() async {
    if (fetchMeResult is MockUser) {
      return fetchMeResult! as MockUser;
    }
    throw fetchMeResult!;
  }

  @override
  Future<void> clearSession() async {
    clearSessionCalls += 1;
  }

  @override
  Future<void> persistSession({required String token, required MockUser user}) async {
    persistSessionCalls += 1;
  }
}

const _cachedUser = MockUser(
  id: 'user-1',
  email: 'ada@example.com',
  role: 'MOCK_CUSTOMER',
  fullName: 'Ada Lovelace',
);

const _storedSession = AuthSession(token: 'stored-token', user: _cachedUser);

Future<void> waitForAuthBootstrap(ProviderContainer container) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    final state = container.read(authControllerProvider);
    if (!state.isInitializing) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Auth bootstrap did not complete');
}

void main() {
  test('bootstrap restores cached session when profile refresh fails transiently', () async {
    final fakeRepository = FakeAuthRepository(
      storedSession: _storedSession,
      fetchMeResult: ApiException('Cannot reach the server. Check your connection.'),
    );

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepository),
      ],
    );
    addTearDown(container.dispose);

    await waitForAuthBootstrap(container);

    final authState = container.read(authControllerProvider);
    expect(authState.isAuthenticated, isTrue);
    expect(authState.user?.email, 'ada@example.com');
    expect(fakeRepository.clearSessionCalls, 0);
  });

  test('bootstrap clears session when profile refresh returns 401', () async {
    final fakeRepository = FakeAuthRepository(
      storedSession: _storedSession,
      fetchMeResult: ApiException('Unauthorized', statusCode: 401),
    );

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepository),
      ],
    );
    addTearDown(container.dispose);

    await waitForAuthBootstrap(container);

    final authState = container.read(authControllerProvider);
    expect(authState.isAuthenticated, isFalse);
    expect(fakeRepository.clearSessionCalls, 1);
  });

  test('bootstrap refreshes profile when network is available', () async {
    const refreshedUser = MockUser(
      id: 'user-1',
      email: 'ada@example.com',
      role: 'MOCK_CUSTOMER',
      fullName: 'Ada Lovelace Updated',
    );

    final fakeRepository = FakeAuthRepository(
      storedSession: _storedSession,
      fetchMeResult: refreshedUser,
    );

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepository),
      ],
    );
    addTearDown(container.dispose);

    await waitForAuthBootstrap(container);

    final authState = container.read(authControllerProvider);
    expect(authState.isAuthenticated, isTrue);
    expect(authState.user?.fullName, 'Ada Lovelace Updated');
    expect(fakeRepository.persistSessionCalls, 1);
    expect(fakeRepository.clearSessionCalls, 0);
  });
}
