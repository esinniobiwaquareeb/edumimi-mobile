import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleSignInResult {
  const AppleSignInResult({required this.idToken, this.email, this.fullName});

  final String idToken;
  final String? email;
  final String? fullName;
}

class AppleSignInService {
  Future<AppleSignInResult> authenticate() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final idToken = credential.identityToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError(
        'Apple did not return a sign-in token. Please try again.',
      );
    }
    final fullName = [credential.givenName, credential.familyName]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .join(' ')
        .trim();
    return AppleSignInResult(
      idToken: idToken,
      email: credential.email,
      fullName: fullName.isEmpty ? null : fullName,
    );
  }
}
