import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/theme/app_theme.dart';
import 'package:mahj_app/features/auth/presentation/forgot_password_screen.dart';

void main() {
  Future<void> pumpForgotPassword(
    WidgetTester tester, {
    Size size = const Size(430, 932),
    double textScale = 1,
    ForgotPasswordScreen screen = const ForgotPasswordScreen(),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: screen,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('forgot password exposes required controls', (tester) async {
    await pumpForgotPassword(tester);

    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.byKey(const ValueKey('forgot-back-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('forgot-lock-image')), findsOneWidget);
    expect(find.byKey(const ValueKey('forgot-email-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('forgot-send-button')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('send-reset-link-button')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('back-to-login-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('reset-link-sent-card')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lock artwork keeps the Figma 96x133 visual frame', (
    tester,
  ) async {
    await pumpForgotPassword(tester);

    expect(
      tester.getSize(find.byKey(const ValueKey('forgot-lock-image-frame'))),
      const Size(96, 133),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('success card appears only after successful callback', (
    tester,
  ) async {
    await pumpForgotPassword(
      tester,
      screen: ForgotPasswordScreen(
        onSendResetLink: (email) async => email == 'user@example.com',
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('forgot-email-field')),
      'user@example.com',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('send-reset-link-button')),
    );
    await tester.tap(find.byKey(const ValueKey('send-reset-link-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reset-link-sent-card')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('reset-link-approved-icon'))),
      const Size.square(24),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('full-width actions keep one 20px body margin', (tester) async {
    await pumpForgotPassword(tester);

    await tester.ensureVisible(
      find.byKey(const ValueKey('send-reset-link-button')),
    );
    final primary = tester.getRect(
      find.byKey(const ValueKey('send-reset-link-button')),
    );
    final secondary = tester.getRect(
      find.byKey(const ValueKey('back-to-login-button')),
    );

    expect(primary.left, 20);
    expect(primary.right, 410);
    expect(secondary.left, 20);
    expect(secondary.right, 410);
  });

  testWidgets('compact viewport remains scroll-safe', (tester) async {
    await pumpForgotPassword(tester, size: const Size(320, 568));

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -500),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('back-to-login-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('larger accessibility text remains usable', (tester) async {
    await pumpForgotPassword(
      tester,
      size: const Size(320, 568),
      textScale: 1.35,
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
