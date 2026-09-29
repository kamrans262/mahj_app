import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/settings/data/legal_preview_data.dart';
import 'package:mahj_app/features/settings/domain/legal_data.dart';
import 'package:mahj_app/features/settings/presentation/legal_screen.dart';

void main() {
  Widget buildScreen({
    LegalDocumentType initialDocument = LegalDocumentType.terms,
  }) {
    return MaterialApp(
      home: LegalScreen(
        terms: LegalPreviewData.terms,
        privacy: LegalPreviewData.privacy,
        initialDocument: initialDocument,
      ),
    );
  }

  testWidgets('Legal screen switches between Terms and Privacy content', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildScreen());
    await tester.pump();

    expect(find.text('Legal'), findsOneWidget);
    expect(find.text('Acceptance of Terms'), findsOneWidget);
    expect(find.text('Information We Collect'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('legal-tab-privacy')));
    await tester.pump();

    expect(find.text('Privacy Policy'), findsWidgets);
    expect(find.text('Information We Collect'), findsOneWidget);
    expect(find.text('Acceptance of Terms'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Legal content remains reachable on a short narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildScreen());
    await tester.pump();

    final scrollView = find.byKey(const ValueKey('legal-scroll-view'));
    expect(scrollView, findsOneWidget);
    final scrollable = find.descendant(
      of: scrollView,
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsOneWidget);

    final target = find.text('Changes to These Terms');
    await tester.scrollUntilVisible(target, 220, scrollable: scrollable);
    await tester.pump();

    expect(target, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Legal can start directly on Privacy Policy', (tester) async {
    await tester.pumpWidget(
      buildScreen(initialDocument: LegalDocumentType.privacy),
    );
    await tester.pump();

    expect(find.text('Information We Collect'), findsOneWidget);
    expect(find.text('Acceptance of Terms'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
