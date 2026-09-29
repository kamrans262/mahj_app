import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/router/app_router.dart';
import 'package:mahj_app/features/profile/presentation/edit_profile_screen.dart';

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
  testWidgets('Profile Edit Profile button opens EditProfileScreen', (
    tester,
  ) async {
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

    await revealProfileEditButton(tester);
    await tester.tap(find.byKey(const ValueKey('profile-edit-button')));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
