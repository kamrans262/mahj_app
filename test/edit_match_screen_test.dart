import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/home/domain/home_match.dart';
import 'package:mahj_app/features/matches/domain/sport_option.dart';
import 'package:mahj_app/features/matches/presentation/create_match_screen.dart';

void main() {
  testWidgets('Edit Match reuses Create Match form and pre-fills details', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final start = DateTime.now().add(const Duration(days: 2));
    final match = HomeMatch(
      id: '42',
      sportName: 'Mah Jongg',
      location: 'Central Park',
      venueName: 'Community Hall',
      notes: 'Bring your set',
      startsAt: start,
      currentPlayers: 2,
      maxPlayers: 4,
      status: MatchStatus.open,
      isOwnedByCurrentUser: true,
    );

    await tester.pumpWidget(MaterialApp(
      home: CreateMatchScreen(
        initialMatch: match,
        sports: const [
          SportOption(id: 1, slug: 'mah-jongg', name: 'Mah Jongg', iconKey: 'generic'),
        ],
      ),
    ));

    expect(find.text('Edit Match'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.text('Create Match'), findsNothing);
    expect(find.text('Central Park'), findsOneWidget);
    expect(find.text('Community Hall'), findsOneWidget);
    expect(find.text('Bring your set'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
