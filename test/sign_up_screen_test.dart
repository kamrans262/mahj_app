import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/theme/app_theme.dart';
import 'package:mahj_app/features/auth/presentation/sign_up_screen.dart';

void main() {
  Future<void> pumpSignUp(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
    SignUpScreen screen = const SignUpScreen(),
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

  testWidgets('sign up screen exposes required controls', (tester) async {
    await pumpSignUp(tester);

    expect(find.text('Create Account'), findsOneWidget);
    expect(find.byKey(const ValueKey('signup-back-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('full-name-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('signup-email-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('signup-password-field')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('confirm-password-field')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('google-signup-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('apple-signup-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('signup-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('login-link')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('full-width controls use one 20px body margin', (tester) async {
    await pumpSignUp(tester);

    final fieldRect = tester.getRect(
      find.byKey(const ValueKey('full-name-field')),
    );
    final googleRect = tester.getRect(
      find.byKey(const ValueKey('google-signup-button')),
    );
    final signupRect = tester.getRect(
      find.byKey(const ValueKey('signup-button')),
    );

    expect(fieldRect.left, 20);
    expect(fieldRect.right, 370);
    expect(googleRect.left, 20);
    expect(googleRect.right, 370);
    expect(signupRect.left, 20);
    expect(signupRect.right, 370);
  });

  testWidgets('social icons stay exactly 24 by 24 logical pixels', (
    tester,
  ) async {
    await pumpSignUp(tester);

    expect(
      tester.getSize(find.byKey(const ValueKey('google-signup-icon'))),
      const Size.square(24),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('apple-signup-icon'))),
      const Size.square(24),
    );
  });

  testWidgets('confirm password validates against password', (tester) async {
    await pumpSignUp(tester);

    await tester.enterText(
      find.byKey(const ValueKey('full-name-field')),
      'Mahj User',
    );
    await tester.enterText(
      find.byKey(const ValueKey('signup-email-field')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('signup-password-field')),
      'secret',
    );
    await tester.enterText(
      find.byKey(const ValueKey('confirm-password-field')),
      'different',
    );

    await tester.ensureVisible(find.byKey(const ValueKey('signup-button')));
    await tester.tap(find.byKey(const ValueKey('signup-button')));
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact viewport remains scroll-safe without overflow', (
    tester,
  ) async {
    await pumpSignUp(tester, size: const Size(320, 568));

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -650),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('signup-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('larger accessibility text remains scroll-safe', (tester) async {
    await pumpSignUp(tester, size: const Size(320, 568), textScale: 1.35);

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back and login callbacks are connected', (tester) async {
    var backTapped = false;
    var loginTapped = false;

    await pumpSignUp(
      tester,
      screen: SignUpScreen(
        onBack: () => backTapped = true,
        onLogin: () => loginTapped = true,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('signup-back-button')));
    await tester.pump();
    expect(backTapped, isTrue);

    await tester.ensureVisible(find.byKey(const ValueKey('login-link')));
    await tester.tap(find.byKey(const ValueKey('login-link')));
    await tester.pump();
    expect(loginTapped, isTrue);
  });
}
