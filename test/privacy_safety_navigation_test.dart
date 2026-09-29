import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/router/app_router.dart';
import 'package:mahj_app/features/settings/presentation/privacy_safety_screen.dart';

void main() {
  testWidgets('Settings Privacy and Safety row opens PrivacySafetyScreen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.settings,
        routes: AppRouter.routes,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pump();

    final privacy = find.byKey(const ValueKey('settings-row-privacy-safety'));
    expect(privacy, findsOneWidget);
    await tester.tap(privacy);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(PrivacySafetyScreen), findsOneWidget);
    expect(find.text('Privacy & Safety'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
