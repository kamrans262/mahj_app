import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/router/app_router.dart';
import 'package:mahj_app/features/home/domain/home_match.dart';
import 'package:mahj_app/features/matches/presentation/invitation_receiving_screen.dart';
import 'package:mahj_app/features/matches/presentation/invite_players_screen.dart';
import 'package:mahj_app/features/matches/presentation/match_details_screen.dart';

HomeMatch _testMatch() {
  return HomeMatch(
    id: 'invitation-flow-test-match',
    sportName: 'Football',
    location: 'Central Park View',
    startsAt: DateTime(2026, 9, 29, 18),
    currentPlayers: 2,
    maxPlayers: 6,
    status: MatchStatus.open,
  );
}

void main() {
  testWidgets(
    'Match Details opens Invite Players and Send invite opens receiving',
    (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final match = _testMatch();

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: TextButton(
                    key: const ValueKey('open-match-details'),
                    onPressed: () {
                      Navigator.of(context)
                          .pushNamed(AppRoutes.matchDetails, arguments: match);
                    },
                    child: const Text('Open Match Details'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('open-match-details')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final inviteButton = find.byKey(
        const ValueKey('match-details-invite-players'),
      );
      expect(inviteButton, findsOneWidget);

      await tester.ensureVisible(inviteButton);
      await tester.pumpAndSettle();
      await tester.tap(inviteButton);
      await tester.pumpAndSettle();

      expect(find.byType(InvitePlayersScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey('invite-players-screen')),
        findsOneWidget,
      );
      expect(find.text('Search Users'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.byKey(const ValueKey('invite-result-demo-invite-1')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('invite-players-send')));
      await tester.pumpAndSettle();

      expect(find.byType(InvitationReceivingScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey('invitation-receiving-screen')),
        findsOneWidget,
      );
      expect(find.text('You are Invited'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('invitation-accept')));
      await tester.pumpAndSettle();
      expect(find.byType(MatchDetailsScreen), findsOneWidget);
      expect(find.text('Leave Match'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('My Matches Invites opens invitation receiving screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.myMatches,
        routes: AppRouter.routes,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final invitesTab = find.byKey(const ValueKey('my-matches-tab-invites'));
    expect(invitesTab, findsOneWidget);
    await tester.tap(invitesTab);
    await tester.pumpAndSettle();

    final firstInvite = find.byKey(const ValueKey('my-match-card-my-invite-1'));
    expect(firstInvite, findsOneWidget);
    expect(find.byType(MyMatchPreviewCard), findsNWidgets(2));
    await tester.ensureVisible(firstInvite);
    await tester.pumpAndSettle();

    await tester.tap(firstInvite);
    await tester.pumpAndSettle();

    expect(find.byType(InvitationReceivingScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey('invitation-receiving-screen')),
      findsOneWidget,
    );
    expect(find.text('You are Invited'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
