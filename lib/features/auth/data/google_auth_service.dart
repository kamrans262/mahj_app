import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_config.dart';

class GoogleAuthException implements Exception {
  const GoogleAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GoogleAuthService {
  GoogleAuthService();

  Future<void>? _initializeFuture;
  bool _initialized = false;

  Future<String?> authenticate() async {
    await _ensureInitialized();

    final signIn = GoogleSignIn.instance;
    if (!signIn.supportsAuthenticate()) {
      throw const GoogleAuthException(
        'Google Sign-In is not available on this device.',
      );
    }

    try {
      final account = await signIn.authenticate();
      final idToken = account.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw const GoogleAuthException(
          'Google did not return a valid sign-in token.',
        );
      }

      return idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }

      if (error.code == GoogleSignInExceptionCode.clientConfigurationError ||
          error.code == GoogleSignInExceptionCode.providerConfigurationError) {
        throw const GoogleAuthException(
          'Google Sign-In is not configured correctly. Check the app OAuth client, SHA fingerprint, and Google services configuration.',
        );
      }

      throw GoogleAuthException(
        error.description?.trim().isNotEmpty == true
            ? error.description!.trim()
            : 'Google Sign-In could not be completed. Please try again.',
      );
    }
  }

  Future<void> signOut() async {
    if (!_initialized) return;

    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Mahj logout must still succeed if Google has no active local session.
    }
  }

  Future<void> _ensureInitialized() {
    return _initializeFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    final configuredServerClientId =
        AppConfig.googleSignInServerClientId.trim();
    final configuredIosClientId = AppConfig.googleSignInIosClientId.trim();

    String? clientId;
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        configuredIosClientId.isNotEmpty) {
      clientId = configuredIosClientId;
    }

    await GoogleSignIn.instance.initialize(
      clientId: clientId,
      serverClientId: configuredServerClientId.isEmpty
          ? null
          : configuredServerClientId,
    );
    _initialized = true;
  }
}
