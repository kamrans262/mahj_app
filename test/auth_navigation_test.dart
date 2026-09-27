import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/router/app_router.dart';
import 'package:mahj_app/app/theme/app_theme.dart';

void main() {
  testWidgets('login Sign Up link opens Create Account and Log In returns', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        initialRoute: AppRoutes.login,
        routes: AppRouter.routes,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('sign-up-link')));
    await tester.tap(find.byKey(const ValueKey('sign-up-link')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('signup-heading')), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('login-link')));
    await tester.tap(find.byKey(const ValueKey('login-link')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('login-heading')), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
