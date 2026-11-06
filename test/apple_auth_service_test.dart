import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/auth/data/apple_auth_service.dart';

void main() {
  test('Apple sign-in is offered only on iOS', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      expect(AppleAuthService.isSupported, isTrue);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(AppleAuthService.isSupported, isFalse);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('authenticate does not open Apple UI on Android', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await expectLater(
        AppleAuthService().authenticate(),
        throwsA(
          isA<AppleAuthException>().having(
            (error) => error.message,
            'message',
            'Apple Sign-In is only available on iPhone and iPad.',
          ),
        ),
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
