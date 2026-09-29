import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/settings/data/support_preview_data.dart';
import 'package:mahj_app/features/settings/domain/support_data.dart';
import 'package:mahj_app/features/settings/presentation/support_screen.dart';

void main() {
  testWidgets(
    'Support screen matches the expected structure without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: SupportScreen(
            faqs: SupportPreviewData.faqs,
            topics: SupportPreviewData.topics,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Support'), findsOneWidget);
      expect(find.text('Frequently Asked Questions'), findsOneWidget);
      expect(find.byKey(const ValueKey('support-faq-group')), findsOneWidget);
      expect(find.text('Contact Support'), findsOneWidget);
      expect(find.byKey(const ValueKey('support-topic-field')), findsOneWidget);
      expect(find.text('Describe your issue'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('support-message-field')),
        findsOneWidget,
      );
      expect(find.text('Add screenshot'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('support-upload-screenshot')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('support-submit-button')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Support remains scrollable on a short narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: SupportScreen(
          faqs: SupportPreviewData.faqs,
          topics: SupportPreviewData.topics,
        ),
      ),
    );
    await tester.pump();

    final scroll = find.byKey(const ValueKey('support-scroll-view'));
    final submit = find.byKey(const ValueKey('support-submit-button'));
    expect(scroll, findsOneWidget);
    expect(submit, findsOneWidget);

    await tester.ensureVisible(submit);
    await tester.pump();

    expect(tester.getRect(submit).bottom, lessThanOrEqualTo(568));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Topic, screenshot and submit callbacks stay backend-ready', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SupportIssueRequest? request;
    await tester.pumpWidget(
      MaterialApp(
        home: SupportScreen(
          faqs: SupportPreviewData.faqs,
          topics: SupportPreviewData.topics,
          onPickScreenshot: () async => const SupportAttachment(
            id: 'shot-1',
            displayName: 'support-shot.png',
          ),
          onSubmitIssue: (value) async {
            request = value;
            return true;
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('support-topic-field')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('support-topic-option-matches')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Matches & invitations'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('support-message-field')),
      'I need help with an invitation.',
    );

    final upload = find.byKey(const ValueKey('support-upload-screenshot'));
    await tester.ensureVisible(upload);
    await tester.tap(upload);
    await tester.pumpAndSettle();
    expect(find.text('support-shot.png'), findsOneWidget);

    final submit = find.byKey(const ValueKey('support-submit-button'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(request, isNotNull);
    expect(request!.topic.id, 'matches');
    expect(request!.message, 'I need help with an invitation.');
    expect(request!.screenshot?.id, 'shot-1');
    expect(tester.takeException(), isNull);
  });
}
