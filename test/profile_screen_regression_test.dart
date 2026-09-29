import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/profile/presentation/profile_screen.dart';

Future<void> revealProfileEditButton(WidgetTester tester) async {
  final button = find.byKey(const ValueKey('profile-edit-button'));
  final scrollView = find.byKey(const ValueKey('profile-scroll-view'));

  for (var attempt = 0; attempt < 8 && button.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollView, const Offset(0, -180));
    await tester.pump();
  }

  expect(button, findsOneWidget);
  await tester.ensureVisible(button);
  await tester.pump();
}

void main() {
  testWidgets(
    'Profile screen matches the main-page structure without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var notificationsTapped = false;
      var messagesTapped = false;
      var editTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            onNotificationTap: () => notificationsTapped = true,
            onMessageTap: () => messagesTapped = true,
            onEditProfile: () => editTapped = true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('My Profile'), findsOneWidget);
      expect(find.byKey(const ValueKey('profile-avatar')), findsOneWidget);
      expect(find.text('Upcoming matches'), findsOneWidget);
      expect(find.text('Completed matches'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.byKey(const ValueKey('profile-header-notifications')),
      );
      await tester.pump();
      expect(notificationsTapped, isTrue);

      await tester.tap(find.byKey(const ValueKey('profile-header-messages')));
      await tester.pump();
      expect(messagesTapped, isTrue);

      await revealProfileEditButton(tester);
      await tester.tap(find.byKey(const ValueKey('profile-edit-button')));
      await tester.pump();
      expect(editTapped, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Profile remains reachable on a short narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pump();

    expect(find.text('My Profile'), findsOneWidget);
    await revealProfileEditButton(tester);
    expect(find.byKey(const ValueKey('profile-edit-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
