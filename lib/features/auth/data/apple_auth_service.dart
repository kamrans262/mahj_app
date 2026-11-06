import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleAuthException implements Exception {
  const AppleAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppleAuthCredential {
  const AppleAuthCredential({
    required this.idToken,
    required this.authorizationCode,
    required this.nonce,
    this.name,
  });

  final String idToken;
  final String authorizationCode;

  /// Raw nonce. The identity token's `nonce` claim is the SHA-256 hex digest of this value.
  final String nonce;
  final String? name;
}

class AppleAuthService {
  const AppleAuthService();

  /// Apple's native sign-in sheet is only available on iOS.
  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<AppleAuthCredential?> authenticate() async {
    if (!isSupported) {
      throw const AppleAuthException(
        'Apple Sign-In is only available on iPhone and iPad.',
      );
    }

    try {
      final available = await SignInWithApple.isAvailable();
      if (!available) {
        throw const AppleAuthException(
          'Apple Sign-In is not available on this device.',
        );
      }

      final rawNonce = generateNonce();
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: _sha256of(rawNonce),
      );

      final idToken = credential.identityToken?.trim() ?? '';
      if (idToken.isEmpty) {
        throw const AppleAuthException(
          'Apple did not return a valid sign-in token.',
        );
      }

      final authorizationCode = credential.authorizationCode.trim();
      if (authorizationCode.isEmpty) {
        throw const AppleAuthException(
          'Apple did not return a valid sign-in code.',
        );
      }

      return AppleAuthCredential(
        idToken: idToken,
        authorizationCode: authorizationCode,
        nonce: rawNonce,
        name: _displayName(credential),
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        return null;
      }

      throw AppleAuthException(_readableMessage(error.message));
    } on SignInWithAppleNotSupportedException {
      throw const AppleAuthException(
        'Apple Sign-In is only available on iPhone and iPad.',
      );
    } on SignInWithAppleCredentialsException catch (error) {
      throw AppleAuthException(_readableMessage(error.message));
    } on PlatformException catch (error) {
      throw AppleAuthException(_readableMessage(error.message));
    }
  }

  String? _displayName(AuthorizationCredentialAppleID credential) {
    final given = credential.givenName?.trim() ?? '';
    final family = credential.familyName?.trim() ?? '';
    final name = [given, family].where((part) => part.isNotEmpty).join(' ');
    return name.isEmpty ? null : name;
  }

  String _readableMessage(String? message) {
    final trimmed = message?.trim() ?? '';
    if (trimmed.isEmpty || trimmed == 'no message provided') {
      return 'Apple Sign-In could not be completed. Please try again.';
    }
    return trimmed;
  }

  String _sha256of(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }
}
