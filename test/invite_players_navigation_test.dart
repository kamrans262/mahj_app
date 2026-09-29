import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/router/app_router.dart';
import 'package:mahj_app/features/home/domain/home_match.dart';
import 'package:mahj_app/features/matches/presentation/invite_players_screen.dart';
import 'package:mahj_app/features/matches/presentation/match_details_screen.dart';

void main() {
  testWidgets('Match Details Invite Players opens Invite Players screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final match = HomeMatch(
      id: 'invite-navigation-test',
      sportName: 'Football',
      location: 'Central Park',
      startsAt: DateTime(2026, 9, 29, 18),
      currentPlayers: 2,
      maxPlayers: 4,
      status: MatchStatus.open,
    );

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed(AppRoutes.matchDetails, arguments: match);
                },
                child: const Text('Open Match Details'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Match Details'));
    await tester.pumpAndSettle();
    expect(find.byType(MatchDetailsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    final inviteButton = find.text('Invite Players');
    expect(inviteButton, findsOneWidget);
    await tester.ensureVisible(inviteButton);
    await tester.tap(inviteButton);
    await tester.pumpAndSettle();

    expect(find.byType(InvitePlayersScreen), findsOneWidget);
    expect(find.text('Search Users'), findsOneWidget);
    expect(find.text('Send invite'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
