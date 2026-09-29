import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/core/widgets/app_button.dart';

void main() {
  testWidgets('compact AppButton is safe as a non-flex Row child', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Expanded(child: Text('4/6 Players')),
                const SizedBox(width: 8),
                AppButton.compactPrimary(
                  label: 'View Details',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.widgetWithText(AppButton, 'View Details'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact AppButton remains overflow-safe at narrow widths', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 83,
              child: AppButton.compactSecondary(
                label: 'Cancel',
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.widgetWithText(AppButton, 'Cancel'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
