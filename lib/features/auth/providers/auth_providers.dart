import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/core/network/api_exception.dart';
import 'package:mock_mobile/features/auth/data/auth_repository.dart';
import 'package:mock_mobile/shared/models/mock_user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({
    required this.status,
    this.session,
    this.errorMessage,
    this.isInitializing = false,
  });

  const AuthState.initializing()
    : this(status: AuthStatus.unknown, isInitializing: true);
  const AuthState.authenticated(AuthSession session)
    : this(status: AuthStatus.authenticated, session: session);
  const AuthState.unauthenticated({String? errorMessage})
    : this(status: AuthStatus.unauthenticated, errorMessage: errorMessage);

  final AuthStatus status;
  final AuthSession? session;
  final String? errorMessage;
  final bool isInitializing;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && session != null;
  MockUser? get user => session?.user;

  @override
  List<Object?> get props => [status, session, errorMessage, isInitializing];
}

class AuthController extends Notifier<AuthState> {
  late AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.read(authRepositoryProvider);
    _bootstrap();
    return const AuthState.initializing();
  }

  Future<void> _bootstrap() async {
    try {
      final stored = await _repository.readStoredSession();
      if (stored == null) {
        state = const AuthState.unauthenticated();
        return;
      }

      // Restore cached session immediately (matches web client) so cold starts stay logged in.
      state = AuthState.authenticated(stored);

      try {
        final freshUser = await _repository.fetchMe();
        state = AuthState.authenticated(
          AuthSession(token: stored.token, user: freshUser),
        );
        await _repository.persistSession(token: stored.token, user: freshUser);
      } on ApiException catch (error) {
        if (error.statusCode == 401) {
          await _repository.clearSession();
          state = const AuthState.unauthenticated();
        }
      }
    } catch (_) {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      final session = await _repository.login(email: email, password: password);
      state = AuthState.authenticated(session);
    } on ApiException catch (error) {
      state = AuthState.unauthenticated(errorMessage: error.message);
      rethrow;
    }
  }

  Future<MockSignupResult> signup({
    required String fullName,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    try {
      final result = await _repository.signup(
        fullName: fullName,
        email: email,
        password: password,
        referralCode: referralCode,
      );
      state = const AuthState.unauthenticated();
      return result;
    } on ApiException catch (error) {
      state = AuthState.unauthenticated(errorMessage: error.message);
      rethrow;
    }
  }

  Future<void> logout({bool localOnly = false}) async {
    await _repository.clearSession();
    state = const AuthState.unauthenticated();
  }

  Future<void> refreshUser() async {
    final current = state.session;
    if (current == null) {
      return;
    }
    try {
      final freshUser = await _repository.fetchMe();
      state = AuthState.authenticated(
        AuthSession(token: current.token, user: freshUser),
      );
      await _repository.persistSession(token: current.token, user: freshUser);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _repository.clearSession();
        state = const AuthState.unauthenticated();
      }
    }
  }

  Future<void> applyVerifiedSession(AuthSession session) async {
    state = AuthState.authenticated(session);
  }

  void updateUser(MockUser user) {
    final current = state.session;
    if (current == null) {
      return;
    }
    state = AuthState.authenticated(
      AuthSession(token: current.token, user: user),
    );
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
