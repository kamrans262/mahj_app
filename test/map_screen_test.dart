import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/home/domain/home_match.dart';
import 'package:mahj_app/features/map/domain/map_match_marker.dart';
import 'package:mahj_app/features/map/presentation/map_screen.dart';

void main() {
  testWidgets('Map marker selection updates the shared detail card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(820, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final tomorrow = DateTime(
      now.year,
      now.month,
      now.day + 1,
      18,
    );

    final basketball = HomeMatch(
      id: 'basketball',
      sportName: 'Basket Ball',
      location: 'Central Park Courts',
      startsAt: tomorrow,
      currentPlayers: 2,
      maxPlayers: 4,
      status: MatchStatus.open,
    );

    final football = HomeMatch(
      id: 'football',
      sportName: 'Football',
      location: 'Riverside Field',
      startsAt: tomorrow.add(const Duration(minutes: 30)),
      currentPlayers: 3,
      maxPlayers: 6,
      status: MatchStatus.open,
    );

    HomeMatch? viewedMatch;

    await tester.pumpWidget(
      MaterialApp(
        home: MapScreen(
          markers: [
            MapMatchMarker(
              match: basketball,
              normalizedX: 0.30,
              normalizedY: 0.62,
              distanceMiles: 3,
            ),
            MapMatchMarker(
              match: football,
              normalizedX: 0.70,
              normalizedY: 0.34,
              distanceMiles: 6,
            ),
          ],
          onViewDetails: (match) {
            viewedMatch = match;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('10 miles'), findsOneWidget);
    expect(find.byKey(const ValueKey('map-demo-canvas')), findsOneWidget);
    expect(find.text('Basket Ball'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('map-marker-football')),
    );
    await tester.pumpAndSettle();

    expect(find.text('3/6 Players'), findsWidgets);

    await tester.tap(find.text('View Details'));
    await tester.pump();

    expect(viewedMatch?.id, 'football');
  });

  testWidgets('Map radius filter can show an empty state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(820, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();

    await tester.pumpWidget(
      MaterialApp(
        home: MapScreen(
          markers: [
            MapMatchMarker(
              match: HomeMatch(
                id: 'far-match',
                sportName: 'Football',
                location: 'Far Field',
                startsAt: now.add(const Duration(days: 1)),
                currentPlayers: 2,
                maxPlayers: 4,
                status: MatchStatus.open,
              ),
              normalizedX: 0.5,
              normalizedY: 0.5,
              distanceMiles: 8,
            ),
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('10 miles'));
    await tester.pumpAndSettle();

    expect(find.text('1 mile'), findsOneWidget);
    expect(find.text('No matches found in this area'), findsOneWidget);
  });
}
