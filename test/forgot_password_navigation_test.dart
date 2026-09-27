import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/router/app_router.dart';
import 'package:mahj_app/app/theme/app_theme.dart';

void main() {
  testWidgets('Forgot Password opens from Login and Back to Login returns', (
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

    await tester.tap(find.byKey(const ValueKey('forgot-password')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('forgot-password-heading')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('back-to-login-button')),
    );
    await tester.tap(find.byKey(const ValueKey('back-to-login-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('login-heading')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
