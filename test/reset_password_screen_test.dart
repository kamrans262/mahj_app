import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/theme/app_theme.dart';
import 'package:mahj_app/features/auth/presentation/reset_password_screen.dart';

void main() {
  testWidgets('reset password validates confirmation and submits', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? submitted;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ResetPasswordScreen(
          onResetPassword: (password) async {
            submitted = password;
            return true;
          },
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('reset-new-password')),
      'new-password123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('reset-confirm-password')),
      'new-password123',
    );
    await tester.tap(
      find.byKey(const ValueKey('reset-password-submit')),
    );
    await tester.pumpAndSettle();

    expect(submitted, 'new-password123');
    expect(tester.takeException(), isNull);
  });
}
