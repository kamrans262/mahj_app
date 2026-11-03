import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mahj_app/core/network/api_client.dart';
import 'package:mahj_app/core/storage/token_store.dart';
import 'package:mahj_app/features/home/data/location_repository.dart';
import 'package:mahj_app/features/home/domain/discovery_location.dart';
import 'package:mahj_app/features/home/domain/home_match.dart';
import 'package:mahj_app/features/home/presentation/home_screen.dart';
import 'package:mahj_app/features/matches/data/match_repository.dart';
import 'package:mahj_app/features/navigation/presentation/main_navigation_shell.dart';
import 'package:mahj_app/features/profile/data/profile_preview_data.dart';

ApiClient _api(MockClient client) => ApiClient(
  baseUrl: 'https://example.test/api',
  tokenStore: SecureTokenStore(useMemoryOnly: true),
  httpClient: client,
);

class _ControlledLocationRepository extends LocationRepository {
  _ControlledLocationRepository()
      : super(
          apiClient: _api(
            MockClient((_) async => http.Response('{"data":[]}', 200)),
          ),
        );

  final Completer<DiscoveryLocation?> gps = Completer<DiscoveryLocation?>();

  void finishGps() {
    if (!gps.isCompleted) {
      gps.complete(const DiscoveryLocation.current(
        latitude: 30.2672,
        longitude: -97.7431,
      ));
    }
  }

  @override
  Future<DiscoveryLocation?> currentLocationIfGranted() => gps.future;

  // The initial Nearby discovery setup still works independently, while
  // Home's own GPS lookup can intentionally remain unresolved.
  @override
  Future<DiscoveryLocation> currentLocation() async =>
      const DiscoveryLocation.current(
        latitude: 30.2672,
        longitude: -97.7431,
      );

  @override
  Future<DiscoveryLocation?> resolveMapTap({
    required double latitude,
    required double longitude,
  }) async => const DiscoveryLocation(
    label: 'Austin, TX',
    latitude: 30.2672,
    longitude: -97.7431,
    city: 'Austin',
    state: 'TX',
  );
}

Map<String, dynamic> _match(
  int id, {
  required String city,
  bool featured = false,
  bool joined = false,
}) => {
  'id': id,
  'name': 'Mah Jongg',
  'location': 'Community Center, $city, TX',
  'starts_at': DateTime.now()
      .add(const Duration(days: 2))
      .toUtc()
      .toIso8601String(),
  'current_players': 2,
  'max_players': 4,
  'status': 'open',
  'can_join': !joined,
  'is_joined': joined,
  'is_public': true,
  'is_invite_only': false,
  'is_featured': featured,
  'latitude': city == 'Austin' ? 30.3 : 32.77,
  'longitude': city == 'Austin' ? -97.7431 : -96.79,
};

http.Response _response(List<Map<String, dynamic>> matches) =>
    http.Response(jsonEncode({'data': matches}), 200);

void _prepareSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('Other-cities message stays hidden while GPS is resolving', (
    tester,
  ) async {
    _prepareSize(tester);
    final location = _ControlledLocationRepository();
    final repository = MatchRepository(apiClient: _api(MockClient((request) async {
      if (request.url.queryParameters['radius_miles'] == '50' ||
          request.url.queryParameters['q'] == 'Austin') {
        return _response([_match(10, city: 'Austin', featured: true)]);
      }
      if (request.url.queryParameters.isEmpty) {
        return _response([_match(30, city: 'Dallas', featured: true)]);
      }
      return _response([]);
    })));

    await tester.pumpWidget(MaterialApp(
      home: MainNavigationShell(
        matchRepository: repository,
        locationRepository: location,
        initialProfileData: ProfilePreviewData.currentUser.copyWith(
          city: 'Austin',
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // The global Dallas result has arrived, but the current GPS point has
    // not. Never call Dallas a final fallback until local checks finish.
    var home = tester.widget<HomeScreen>(find.byType(HomeScreen));
    expect(home.data!.isUpcomingMatchesLoading, isTrue);
    expect(home.data!.isShowingOtherCities, isFalse);
    expect(find.byKey(const ValueKey('featured-other-cities-subtitle')),
        findsNothing);
    expect(find.text('Finding upcoming matches...'), findsOneWidget);

    location.finishGps();
    await tester.pumpAndSettle();

    home = tester.widget<HomeScreen>(find.byType(HomeScreen));
    expect(home.data!.isUpcomingMatchesLoading, isFalse);
    expect(home.data!.upcomingMatches.map((m) => m.id), ['10']);
    expect(home.data!.isShowingOtherCities, isFalse);
    expect(find.byKey(const ValueKey('featured-other-cities-subtitle')),
        findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('After joining last local match, wait before showing other cities', (
    tester,
  ) async {
    _prepareSize(tester);
    final location = _ControlledLocationRepository();
    location.finishGps();
    var joinedLocal = false;
    var radiusRequests = 0;
    final secondRadiusResponse = Completer<http.Response>();

    final repository = MatchRepository(apiClient: _api(MockClient((request) async {
      final query = request.url.queryParameters;
      if (query['radius_miles'] == '50') {
        radiusRequests++;
        if (radiusRequests > 1) {
          return secondRadiusResponse.future;
        }
        return _response([_match(10, city: 'Austin', featured: true)]);
      }
      if (query['q'] == 'Austin') {
        return _response(
          joinedLocal ? [] : [_match(10, city: 'Austin', featured: true)],
        );
      }
      if (query.isEmpty) {
        return _response([
          _match(10, city: 'Austin', joined: joinedLocal),
          _match(30, city: 'Dallas', featured: true),
        ]);
      }
      return _response([]);
    })));

    await tester.pumpWidget(MaterialApp(
      home: MainNavigationShell(
        matchRepository: repository,
        locationRepository: location,
        initialProfileData: ProfilePreviewData.currentUser.copyWith(
          city: 'Austin',
        ),
        onMatchTap: (match) async {
          // Simulate the user successfully joining via Match Details.
          joinedLocal = true;
        },
      ),
    ));
    await tester.pumpAndSettle();

    var home = tester.widget<HomeScreen>(find.byType(HomeScreen));
    expect(home.data!.upcomingMatches.map((m) => m.id), ['10']);
    expect(home.data!.isShowingOtherCities, isFalse);

    // Returning from the joined match triggers a fresh global and local
    // search. Global now contains only Dallas as a joinable option, but the
    // new GPS-radius response has intentionally not finished.
    final joined = home.data!.upcomingMatches.single;
    await home.onJoinMatch!(joined);
    await tester.pumpAndSettle();

    home = tester.widget<HomeScreen>(find.byType(HomeScreen));
    expect(home.data!.isUpcomingMatchesLoading, isTrue);
    expect(home.data!.isShowingOtherCities, isFalse);
    expect(find.byKey(const ValueKey('featured-other-cities-subtitle')),
        findsNothing);
    expect(find.text('Finding upcoming matches...'), findsOneWidget);

    secondRadiusResponse.complete(_response([]));
    await tester.pumpAndSettle();

    home = tester.widget<HomeScreen>(find.byType(HomeScreen));
    expect(home.data!.isUpcomingMatchesLoading, isFalse);
    expect(home.data!.upcomingMatches.map((m) => m.id), ['30']);
    expect(home.data!.isShowingOtherCities, isTrue);
    expect(find.text('Explore open matches in other cities'), findsOneWidget);
    expect(home.data!.upcomingMatches.any((HomeMatch m) => m.id == '10'),
        isFalse);
    expect(tester.takeException(), isNull);
  });
}
