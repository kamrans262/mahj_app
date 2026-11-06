import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/theme/app_theme.dart';
import 'package:mahj_app/features/auth/presentation/login_screen.dart';

void main() {
  Future<void> pumpLogin(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
    bool showAppleSignIn = true,
    LoginScreen? screen,
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
          child: screen ?? LoginScreen(showAppleSignIn: showAppleSignIn),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('login screen exposes required controls', (tester) async {
    await pumpLogin(tester);

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login to Continue'), findsOneWidget);
    expect(find.byKey(const ValueKey('email-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('password-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('google-login-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('apple-login-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('login-button')), findsOneWidget);
  });

  testWidgets('apple login stays hidden on Android', (tester) async {
    await pumpLogin(tester, showAppleSignIn: false);

    expect(find.byKey(const ValueKey('google-login-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('apple-login-button')), findsNothing);
    expect(find.text('Continue with Apple'), findsNothing);
  });

  testWidgets('apple login button calls its callback on iOS', (tester) async {
    var tapped = false;
    await pumpLogin(
      tester,
      screen: LoginScreen(
        showAppleSignIn: true,
        onAppleLogin: () async {
          tapped = true;
        },
      ),
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('apple-login-button')),
    );
    await tester.tap(find.byKey(const ValueKey('apple-login-button')));
    await tester.pump();

    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('social icons stay exactly 24 by 24 logical pixels', (
    tester,
  ) async {
    await pumpLogin(tester);

    expect(
      tester.getSize(find.byKey(const ValueKey('google-login-icon'))),
      const Size.square(24),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('apple-login-icon'))),
      const Size.square(24),
    );
  });

  testWidgets('compact viewport remains scroll-safe without overflow', (
    tester,
  ) async {
    await pumpLogin(tester, size: const Size(320, 568));

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -500),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('login-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('larger accessibility text remains scroll-safe', (tester) async {
    await pumpLogin(tester, size: const Size(320, 568), textScale: 1.35);

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
