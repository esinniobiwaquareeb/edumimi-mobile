import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:mock_mobile/core/config/app_config.dart';

class GoogleSignInService {
  static bool _initialized = false;

  Future<String> authenticate() async {
    if (AppConfig.googleServerClientId.isEmpty) {
      throw StateError('Google sign-in is not configured for this app build.');
    }
    if (!_initialized) {
      await GoogleSignIn.instance.initialize(
        clientId: Platform.isIOS && AppConfig.googleIosClientId.isNotEmpty
            ? AppConfig.googleIosClientId
            : null,
        serverClientId: AppConfig.googleServerClientId,
      );
      _initialized = true;
    }
    final account = await GoogleSignIn.instance.authenticate();
    final token = account.authentication.idToken;
    if (token == null || token.isEmpty) {
      throw StateError(
        'Google did not return a sign-in token. Please try again.',
      );
    }
    return token;
  }
}
