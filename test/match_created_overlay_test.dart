import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/home/domain/home_match.dart';
import 'package:mahj_app/features/matches/presentation/widgets/match_created_overlay.dart';

void main() {
  testWidgets('success overlay hides status and player count', (tester) async {
    final match = HomeMatch(
      id: 'created-1',
      sportName: 'Basket Ball',
      location: 'Central Park Courts',
      startsAt: DateTime.now().add(const Duration(days: 1)),
      currentPlayers: 2,
      maxPlayers: 4,
      status: MatchStatus.open,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              const SizedBox.expand(),
              MatchCreatedOverlay(match: match, onBackHome: (_) {}),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Match Created'), findsOneWidget);
    expect(
      find.text('The match has been created successfully'),
      findsOneWidget,
    );
    expect(find.text('Basket Ball'), findsOneWidget);
    expect(find.text('Open'), findsNothing);
    expect(find.text('2/4 Players'), findsNothing);
    expect(find.text('Invite Players'), findsOneWidget);
    expect(find.text('Back home'), findsOneWidget);
    expect(find.text('View Match'), findsOneWidget);
  });
}
