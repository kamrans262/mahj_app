import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/home/data/home_preview_data.dart';
import 'package:mahj_app/features/home/domain/home_data.dart';
import 'package:mahj_app/features/home/domain/home_match.dart';
import 'package:mahj_app/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('Home labels cross-city featured fallback and exposes the city', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final preview = HomePreviewData.create();
    final game = HomeMatch(
      id: 'remote-upcoming',
      sportName: 'Mah Jongg',
      location: 'Community Center, Dallas, TX',
      startsAt: DateTime.now().add(const Duration(days: 2)),
      currentPlayers: 2,
      maxPlayers: 4,
      status: MatchStatus.open,
      distanceMiles: 32,
    );

    HomeData data({required bool showFallback}) => HomeData(
      greeting: preview.greeting,
      displayName: preview.displayName,
      subtitle: preview.subtitle,
      location: preview.location,
      unreadNotificationCount: 0,
      unreadMessageCount: 0,
      upcomingMatches: [game],
      nearbyMatches: const [],
      isShowingOtherCities: showFallback,
    );

    await tester.pumpWidget(MaterialApp(
      home: HomeScreen(data: data(showFallback: true)),
    ));
    await tester.pump();

    expect(find.text('Upcoming Matches'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('featured-other-cities-subtitle')),
      findsOneWidget,
    );
    expect(find.text('Explore open matches in other cities'), findsOneWidget);
    expect(find.text('Dallas, TX · 32.0 miles away'), findsOneWidget);
    expect(find.text('Nearby Matches'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(MaterialApp(
      home: HomeScreen(data: data(showFallback: false)),
    ));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('featured-other-cities-subtitle')),
      findsNothing,
    );
    expect(find.text('Community Center, Dallas, TX'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
