import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/core/widgets/app_text_field.dart';
import 'package:mahj_app/features/profile/data/profile_preview_data.dart';

void main() {
  testWidgets(
    'Profile model and AppTextField stay compatible with Edit Profile',
    (tester) async {
      final profile = ProfilePreviewData.currentUser.copyWith(
        phone: '+1 555 0100',
        city: 'Central City',
        state: 'NY',
        bio: 'Football player',
      );

      expect(profile.phone, '+1 555 0100');
      expect(profile.city, 'Central City');
      expect(profile.state, 'NY');
      expect(profile.bio, 'Football player');

      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              hintText: 'Full Name',
              textCapitalization: TextCapitalization.words,
            ),
          ),
        ),
      );

      final textFieldFinder = find.descendant(
        of: find.byType(AppTextField),
        matching: find.byType(TextField),
      );
      expect(textFieldFinder, findsOneWidget);

      final field = tester.widget<TextField>(textFieldFinder);
      expect(field.textCapitalization, TextCapitalization.words);
      expect(tester.takeException(), isNull);
    },
  );
}
