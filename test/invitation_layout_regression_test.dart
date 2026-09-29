import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/home/domain/home_match.dart';
import 'package:mahj_app/features/matches/data/invite_players_preview_data.dart';
import 'package:mahj_app/features/matches/presentation/invitation_receiving_screen.dart';
import 'package:mahj_app/features/matches/presentation/invite_players_screen.dart';
import 'package:mahj_app/features/matches/presentation/widgets/invite_result_card.dart';

HomeMatch _match({
  MatchStatus status = MatchStatus.open,
  int currentPlayers = 2,
  int maxPlayers = 6,
}) {
  return HomeMatch(
    id: 'invitation-layout-test-match',
    sportName: 'Football',
    location: 'Central Park View',
    startsAt: DateTime(2026, 9, 29, 18),
    currentPlayers: currentPlayers,
    maxPlayers: maxPlayers,
    status: status,
  );
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
}

void main() {
  testWidgets('InviteResultCard has finite natural height in a list', (
    tester,
  ) async {
    _setViewport(tester, const Size(430, 900));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final result = InvitePlayersPreviewData.forMatch(_match()).first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              InviteResultCard(result: result, isSelected: true, onTap: () {}),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final size = tester.getSize(find.byType(InviteResultCard));
    expect(size.height.isFinite, isTrue);
    expect(size.height, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Invite Players is safe on a short narrow phone', (tester) async {
    _setViewport(tester, const Size(320, 560));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var previewOpened = false;
    final match = _match();

    await tester.pumpWidget(
      MaterialApp(
        home: InvitePlayersScreen(
          match: match,
          initialResults: InvitePlayersPreviewData.forMatch(match),
          onPreviewInvitationReceived: () => previewOpened = true,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('invite-players-screen')), findsOneWidget);
    expect(find.text('Search Users'), findsOneWidget);
    expect(find.byKey(const ValueKey('invite-players-send')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('invite-result-demo-invite-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('invite-players-send')));
    await tester.pump();

    expect(previewOpened, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Invitation Receiving renders with finite layout', (
    tester,
  ) async {
    _setViewport(tester, const Size(430, 900));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: InvitationReceivingScreen(
          match: _match(),
          onDecline: (_) async {},
          onAccept: (_) async {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('You are Invited'), findsOneWidget);
    final invitedHeroSize = tester.getSize(
      find.byKey(const ValueKey('invitation-hero')),
    );
    expect(invitedHeroSize.width, 390);
    expect(find.byKey(const ValueKey('invitation-decline')), findsOneWidget);
    expect(find.byKey(const ValueKey('invitation-accept')), findsOneWidget);
    expect(find.byType(IntrinsicHeight), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Invitation Receiving remains safe on short narrow phone', (
    tester,
  ) async {
    _setViewport(tester, const Size(320, 560));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: InvitationReceivingScreen(
          match: _match(),
          onDecline: (_) async {},
          onAccept: (_) async {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('You are Invited'), findsOneWidget);
    expect(find.byKey(const ValueKey('invitation-accept')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cannot Join state uses one safe Okay action', (tester) async {
    _setViewport(tester, const Size(320, 560));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: InvitationReceivingScreen(
          match: _match(
            status: MatchStatus.full,
            currentPlayers: 6,
            maxPlayers: 6,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('You Cannot Join'), findsOneWidget);
    final cannotJoinHeroSize = tester.getSize(
      find.byKey(const ValueKey('invitation-hero')),
    );
    expect(cannotJoinHeroSize.width, 280);
    expect(find.byKey(const ValueKey('invitation-okay')), findsOneWidget);
    expect(find.byKey(const ValueKey('invitation-accept')), findsNothing);
    expect(find.byKey(const ValueKey('invitation-decline')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
