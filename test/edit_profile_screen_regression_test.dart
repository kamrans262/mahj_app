import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/profile/data/profile_preview_data.dart';
import 'package:mahj_app/features/profile/domain/profile_data.dart';
import 'package:mahj_app/features/profile/presentation/edit_profile_screen.dart';

void main() {
  testWidgets('Edit Profile renders reusable form without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    ProfileData? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: EditProfileScreen(
          profile: ProfilePreviewData.currentUser,
          onSave: (draft) async {
            saved = draft;
            return draft;
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.byKey(const ValueKey('edit-profile-avatar')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('edit-profile-change-photo')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('edit-profile-full-name')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('edit-profile-phone')), findsOneWidget);
    expect(find.byKey(const ValueKey('edit-profile-zip')), findsOneWidget);
    expect(find.byKey(const ValueKey('edit-profile-city')), findsOneWidget);
    expect(find.byKey(const ValueKey('edit-profile-state')), findsOneWidget);
    expect(find.byKey(const ValueKey('edit-profile-bio')), findsOneWidget);
    expect(tester.takeException(), isNull);

    final fullNameInput = find.descendant(
      of: find.byKey(const ValueKey('edit-profile-full-name')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(fullNameInput, 'Austen Parker Updated');
    await tester.pump();

    final save = find.byKey(const ValueKey('edit-profile-save'));
    await tester.ensureVisible(save);
    await tester.pump();
    await tester.tap(save);
    await tester.pump();

    expect(saved?.name, 'Austen Parker Updated');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Edit Profile remains scrollable on a short narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: EditProfileScreen(profile: ProfilePreviewData.currentUser),
      ),
    );
    await tester.pump();

    final save = find.byKey(const ValueKey('edit-profile-save'));
    expect(save, findsOneWidget);
    await tester.ensureVisible(save);
    await tester.pump();

    expect(find.byKey(const ValueKey('edit-profile-cancel')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
