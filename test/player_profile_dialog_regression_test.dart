import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/profile/data/player_profile_preview_data.dart';
import 'package:mahj_app/features/profile/presentation/player_profile_screen.dart';

Future<void> _scrollToAction(WidgetTester tester, Key key) async {
  final target = find.byKey(key);
  final scrollView = find.byKey(const ValueKey('player-profile-scroll-view'));
  for (var attempt = 0; attempt < 8 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollView, const Offset(0, -280));
    await tester.pump();
  }
  expect(target, findsOneWidget);
}

Future<void> _selectReasonOption(
  WidgetTester tester, {
  required String reasonId,
}) async {
  final list = find.byKey(const ValueKey('report-reason-options-list'));
  final option = find.byKey(ValueKey('report-reason-option-$reasonId'));

  expect(list, findsOneWidget);
  for (var attempt = 0; attempt < 8 && option.evaluate().isEmpty; attempt++) {
    await tester.drag(list, const Offset(0, -72));
    await tester.pump();
  }

  expect(option, findsOneWidget);
  await tester.ensureVisible(option);
  await tester.pump();
  await tester.tap(option);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Report reason selector is functional and cancel closes popup', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: PlayerProfileScreen(player: PlayerProfilePreviewData.demo),
      ),
    );
    await tester.pump();

    const reportKey = ValueKey('player-profile-report');
    await _scrollToAction(tester, reportKey);
    await tester.tap(find.byKey(reportKey));
    await tester.pumpAndSettle();

    expect(find.text('Report Austen Parker?'), findsOneWidget);
    expect(find.byKey(const ValueKey('report-reason-field')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('report-reason-field')));
    await tester.pumpAndSettle();
    await _selectReasonOption(tester, reasonId: 'inappropriate_behavior');

    expect(find.text('Inappropriate behavior'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('report-cancel-button')));
    await tester.pumpAndSettle();

    expect(find.text('Report Austen Parker?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Block reason selector is functional and cancel closes popup', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: PlayerProfileScreen(player: PlayerProfilePreviewData.demo),
      ),
    );
    await tester.pump();

    const blockKey = ValueKey('player-profile-block');
    await _scrollToAction(tester, blockKey);
    await tester.tap(find.byKey(blockKey));
    await tester.pumpAndSettle();

    expect(find.text('Block Austen Parker?'), findsOneWidget);
    expect(find.byKey(const ValueKey('block-reason-field')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('block-reason-field')));
    await tester.pumpAndSettle();
    await _selectReasonOption(tester, reasonId: 'safety_concern');

    expect(find.text('Safety concern'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('block-cancel-button')));
    await tester.pumpAndSettle();

    expect(find.text('Block Austen Parker?'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
