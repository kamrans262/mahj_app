import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/core/widgets/app_text_field.dart';

void main() {
  testWidgets('AppTextField dismisses focus when tapping outside', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();

    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                AppTextField(
                  controller: controller,
                  focusNode: focusNode,
                  hintText: 'E-mail',
                  leadingIcon: Icons.email_outlined,
                ),
                const SizedBox(height: 20),
                Container(
                  key: const Key('outside-tap-target'),
                  width: double.infinity,
                  height: 120,
                  color: Colors.transparent,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.byKey(const Key('outside-tap-target')));
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
  });
}
