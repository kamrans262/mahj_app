import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/router/app_router.dart';
import 'package:mahj_app/features/settings/presentation/settings_screen.dart';

void main() {
  testWidgets('My Profile Settings row opens SettingsScreen', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profile,
        routes: AppRouter.routes,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pump();

    final settingsRow = find.byKey(const ValueKey('profile-settings-row'));
    expect(settingsRow, findsOneWidget);
    await tester.tap(settingsRow);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(SettingsScreen), findsOneWidget);
    final settingsScreen = find.byKey(const ValueKey('settings-screen'));
    expect(settingsScreen, findsOneWidget);

    final settingsTitle = find.descendant(
      of: settingsScreen,
      matching: find.text('Settings'),
    );
    expect(settingsTitle, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
