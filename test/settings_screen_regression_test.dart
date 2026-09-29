import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/settings/presentation/settings_screen.dart';

void main() {
  testWidgets('Settings renders grouped rows and remains scroll-safe', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pump();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('Safety'), findsOneWidget);
    expect(find.text('Help & Support'), findsOneWidget);
    expect(find.text('Legal'), findsOneWidget);
    expect(find.text('Account Settings'), findsOneWidget);
    expect(find.text('Notification'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Subscription'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final deleteRow = find.byKey(const ValueKey('settings-row-delete-account'));
    final scrollView = find.byKey(const ValueKey('settings-scroll-view'));
    for (
      var attempt = 0;
      attempt < 8 && deleteRow.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(scrollView, const Offset(0, -260));
      await tester.pump();
    }
    expect(deleteRow, findsOneWidget);

    expect(find.text('Delete Account'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings remains usable on a short narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pump();

    final deleteRow = find.byKey(const ValueKey('settings-row-delete-account'));
    final scrollView = find.byKey(const ValueKey('settings-scroll-view'));
    for (
      var attempt = 0;
      attempt < 10 && deleteRow.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(scrollView, const Offset(0, -240));
      await tester.pump();
    }
    expect(deleteRow, findsOneWidget);

    expect(deleteRow, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Delete Account uses confirmation dialog before submission', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var deleteCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          onDeleteAccount: () async {
            deleteCalls++;
            return false;
          },
        ),
      ),
    );
    await tester.pump();

    final deleteRow = find.byKey(const ValueKey('settings-row-delete-account'));
    final scrollView = find.byKey(const ValueKey('settings-scroll-view'));
    for (
      var attempt = 0;
      attempt < 8 && deleteRow.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(scrollView, const Offset(0, -260));
      await tester.pump();
    }
    expect(deleteRow, findsOneWidget);
    await tester.tap(deleteRow);
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.text('Delete Account?'), findsOneWidget);
    expect(deleteCalls, 0);
    expect(tester.takeException(), isNull);
  });
}
