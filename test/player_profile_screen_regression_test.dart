import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/profile/data/player_profile_preview_data.dart';
import 'package:mahj_app/features/profile/presentation/player_profile_screen.dart';

void main() {
  testWidgets('Player Profile renders selected-player data without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: PlayerProfileScreen(
          player: PlayerProfilePreviewData.demo,
          notificationCount: 3,
          messageCount: 3,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Players Profile'), findsOneWidget);
    expect(find.text('Austen Parker'), findsOneWidget);
    expect(find.byKey(const ValueKey('player-profile-avatar')), findsOneWidget);
    expect(find.byKey(const ValueKey('player-profile-stats')), findsOneWidget);
    expect(find.text('Matches Played'), findsOneWidget);
    expect(find.text('Matches Hosted'), findsOneWidget);
    expect(find.text('Attendance'), findsOneWidget);
    expect(find.text('Member since'), findsOneWidget);
    expect(find.text('Mutual Games (0)'), findsOneWidget);
    expect(find.text('No mutual games yet'), findsOneWidget);
    expect(find.text(PlayerProfilePreviewData.demo.email), findsNothing);
    expect(find.text(PlayerProfilePreviewData.demo.addressLine), findsNothing);
    expect(find.byType(SliverFillRemaining), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mutual Games stays within narrow profile and View All receives tap', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var tapped = false;
    final player = PlayerProfilePreviewData.demo;
    await tester.pumpWidget(
      MaterialApp(
        home: PlayerProfileScreen(
          player: player,
          onViewAllMutualGames: () => tapped = true,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Mutual Games (0)'), findsOneWidget);
    await tester.ensureVisible(find.text('View All'));
    await tester.tap(find.text('View All'));
    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Player Profile actions remain reachable on a short phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: PlayerProfileScreen(player: PlayerProfilePreviewData.demo),
      ),
    );
    await tester.pump();

    final block = find.byKey(const ValueKey('player-profile-block'));
    final scrollView = find.byKey(const ValueKey('player-profile-scroll-view'));
    for (var attempt = 0; attempt < 6 && block.evaluate().isEmpty; attempt++) {
      await tester.drag(scrollView, const Offset(0, -280));
      await tester.pump();
    }
    expect(block, findsOneWidget);

    expect(
      find.byKey(const ValueKey('player-profile-send-invite')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('player-profile-report')), findsOneWidget);
    expect(block, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
