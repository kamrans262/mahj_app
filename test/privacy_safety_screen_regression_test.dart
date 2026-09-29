import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/settings/data/privacy_safety_preview_data.dart';
import 'package:mahj_app/features/settings/presentation/privacy_safety_screen.dart';

void main() {
  testWidgets('Privacy & Safety renders grouped sections without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: PrivacySafetyScreen(
          blockedUsers: PrivacySafetyPreviewData.blockedUsers,
          rules: PrivacySafetyPreviewData.rules,
          reportHistory: PrivacySafetyPreviewData.reportHistory,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Privacy & Safety'), findsOneWidget);
    expect(find.text('Blocked Users'), findsOneWidget);
    expect(find.text('Rules to Follow'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('privacy-blocked-users-container')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('privacy-rules-container')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('privacy-unblock-austen')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Privacy & Safety report history remains reachable on short phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: PrivacySafetyScreen(
            blockedUsers: PrivacySafetyPreviewData.blockedUsers,
            rules: PrivacySafetyPreviewData.rules,
            reportHistory: PrivacySafetyPreviewData.reportHistory,
          ),
        ),
      );
      await tester.pump();

      final reportHistory = find.byKey(
        const ValueKey('privacy-report-history-container'),
      );
      final scrollView = find.byKey(
        const ValueKey('privacy-safety-scroll-view'),
      );

      for (
        var attempt = 0;
        attempt < 8 && reportHistory.evaluate().isEmpty;
        attempt++
      ) {
        await tester.drag(scrollView, const Offset(0, -240));
        await tester.pump();
      }

      expect(reportHistory, findsOneWidget);
      expect(find.text('Report History'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('successful Unblock removes only the confirmed user', (
    tester,
  ) async {
    String? unblockedId;

    await tester.pumpWidget(
      MaterialApp(
        home: PrivacySafetyScreen(
          blockedUsers: PrivacySafetyPreviewData.blockedUsers,
          rules: PrivacySafetyPreviewData.rules,
          reportHistory: PrivacySafetyPreviewData.reportHistory,
          onUnblock: (playerId) async {
            unblockedId = playerId;
            return true;
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('privacy-unblock-austen')));
    await tester.pumpAndSettle();

    expect(unblockedId, 'austen');
    expect(find.byKey(const ValueKey('privacy-unblock-austen')), findsNothing);
    expect(find.byKey(const ValueKey('privacy-unblock-alex')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
