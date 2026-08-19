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
  });

  const AuthState.unknown() : this(status: AuthStatus.unknown);
  const AuthState.authenticated(AuthSession session)
      : this(status: AuthStatus.authenticated, session: session);
  const AuthState.unauthenticated({String? errorMessage})
      : this(status: AuthStatus.unauthenticated, errorMessage: errorMessage);

  final AuthStatus status;
  final AuthSession? session;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated && session != null;
  MockUser? get user => session?.user;

  @override
  List<Object?> get props => [status, session, errorMessage];
}

class AuthController extends Notifier<AuthState> {
  late AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.read(authRepositoryProvider);
    _bootstrap();
    return const AuthState.unknown();
  }

  Future<void> _bootstrap() async {
    try {
      final stored = await _repository.readStoredSession();
      if (stored == null) {
        state = const AuthState.unauthenticated();
        return;
      }
      final freshUser = await _repository.fetchMe();
      state = AuthState.authenticated(AuthSession(token: stored.token, user: freshUser));
    } catch (_) {
      await _repository.clearSession();
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AuthState.unknown();
    try {
      final session = await _repository.login(email: email, password: password);
      state = AuthState.authenticated(session);
    } on ApiException catch (error) {
      state = AuthState.unauthenticated(errorMessage: error.message);
      rethrow;
    }
  }

  Future<void> signup({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = const AuthState.unknown();
    try {
      final session = await _repository.signup(
        fullName: fullName,
        email: email,
        password: password,
      );
      state = AuthState.authenticated(session);
    } on ApiException catch (error) {
      state = AuthState.unauthenticated(errorMessage: error.message);
      rethrow;
    }
  }

  Future<void> logout({bool localOnly = false}) async {
    await _repository.clearSession();
    state = const AuthState.unauthenticated();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
