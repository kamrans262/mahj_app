import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/home/domain/home_match.dart';
import 'package:mahj_app/features/map/domain/map_match_marker.dart';
import 'package:mahj_app/features/map/presentation/map_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  HomeMatch matchFor({
    required String id,
    required DateTime startsAt,
    required String location,
    int currentPlayers = 2,
    int maxPlayers = 4,
  }) {
    return HomeMatch(
      id: id,
      sportName: 'Football',
      location: location,
      startsAt: startsAt,
      currentPlayers: currentPlayers,
      maxPlayers: maxPlayers,
      status: MatchStatus.open,
    );
  }

  testWidgets(
    'Map marker selection updates details and View Details callback',
    (tester) async {
      tester.view.physicalSize = const Size(820, 1500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 18);

      final first = matchFor(
        id: 'basketball',
        startsAt: today,
        location: 'Central Park Courts',
      );
      final second = matchFor(
        id: 'football',
        startsAt: today.add(const Duration(minutes: 30)),
        location: 'Riverside Field',
        currentPlayers: 3,
        maxPlayers: 6,
      );

      HomeMatch? viewedMatch;

      await tester.pumpWidget(
        MaterialApp(
          home: MapScreen(
            markers: [
              MapMatchMarker(
                match: first,
                normalizedX: 0.30,
                normalizedY: 0.62,
                distanceMiles: 3,
              ),
              MapMatchMarker(
                match: second,
                normalizedX: 0.70,
                normalizedY: 0.34,
                distanceMiles: 6,
              ),
            ],
            onViewDetails: (match) => viewedMatch = match,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('10 miles'), findsOneWidget);
      expect(find.byKey(const ValueKey('map-demo-canvas')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('map-marker-football')));
      await tester.pumpAndSettle();

      expect(find.text('3/6 Players'), findsWidgets);

      await tester.tap(find.text('View Details'));
      await tester.pump();

      expect(viewedMatch?.id, 'football');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Map date filter switches between Today and Tomorrow data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(820, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 18);
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 18);

    await tester.pumpWidget(
      MaterialApp(
        home: MapScreen(
          markers: [
            MapMatchMarker(
              match: matchFor(
                id: 'today-match',
                startsAt: today,
                location: 'Today Field',
              ),
              normalizedX: 0.30,
              normalizedY: 0.62,
              distanceMiles: 3,
            ),
            MapMatchMarker(
              match: matchFor(
                id: 'tomorrow-match',
                startsAt: tomorrow,
                location: 'Tomorrow Field',
              ),
              normalizedX: 0.70,
              normalizedY: 0.34,
              distanceMiles: 3,
            ),
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('map-marker-today-match')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('map-marker-tomorrow-match')),
      findsNothing,
    );

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    expect(find.text('Tomorrow'), findsOneWidget);
    expect(find.byKey(const ValueKey('map-marker-today-match')), findsNothing);
    expect(
      find.byKey(const ValueKey('map-marker-tomorrow-match')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Map radius filter can show an empty state', (tester) async {
    tester.view.physicalSize = const Size(820, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 18);

    await tester.pumpWidget(
      MaterialApp(
        home: MapScreen(
          markers: [
            MapMatchMarker(
              match: matchFor(
                id: 'far-match',
                startsAt: today,
                location: 'Far Field',
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
    expect(tester.takeException(), isNull);
  });
}
