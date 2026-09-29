import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/navigation/presentation/main_navigation_shell.dart';
import 'package:mahj_app/features/profile/presentation/profile_screen.dart';

void main() {
  testWidgets('Bottom navigation opens Profile as the fourth main tab', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: MainNavigationShell()));
    await tester.pump();

    await tester.tap(find.text('Profile'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('My Profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
