import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mahj_app/core/network/api_client.dart';
import 'package:mahj_app/core/storage/token_store.dart';
import 'package:mahj_app/features/home/data/location_repository.dart';
import 'package:mahj_app/features/home/data/match_discovery_store.dart';
import 'package:mahj_app/features/home/domain/discovery_location.dart';
import 'package:mahj_app/features/home/domain/match_filters.dart';
import 'package:mahj_app/features/home/presentation/home_screen.dart';
import 'package:mahj_app/features/matches/data/match_repository.dart';
import 'package:mahj_app/features/navigation/presentation/main_navigation_shell.dart';
import 'package:mahj_app/features/profile/data/profile_preview_data.dart';

class _AustinLocationRepository extends LocationRepository {
  _AustinLocationRepository()
    : super(
        apiClient: ApiClient(
          baseUrl: 'https://example.test/api',
          tokenStore: SecureTokenStore(useMemoryOnly: true),
          httpClient: MockClient((_) async => http.Response('{"data":[]}', 200)),
        ),
      );

  int locationReads = 0;

  @override
  Future<DiscoveryLocation?> currentLocationIfGranted() async {
    locationReads++;
    return const DiscoveryLocation.current(
      latitude: 30.2672,
      longitude: -97.7431,
    );
  }

  @override
  Future<DiscoveryLocation?> resolveMapTap({
    required double latitude,
    required double longitude,
  }) async {
    return const DiscoveryLocation(
      label: 'Austin, TX',
      city: 'Austin',
      state: 'TX',
      latitude: 30.2672,
      longitude: -97.7431,
    );
  }
}

void main() {
  testWidgets('Home banner fetches GPS 50-mile matches without changing discovery filters', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final requests = <Uri>[];
    final futureTime = DateTime.now().add(const Duration(days: 2))
        .toUtc().toIso8601String();

    Map<String, dynamic> record(
      int id, {
      required String city,
      bool featured = false,
      double? latitude,
      double? longitude,
    }) => {
      'id': id,
      'name': 'Mah Jongg',
      'location': 'Community Center, $city, TX',
      'starts_at': futureTime,
      'current_players': 2,
      'max_players': 4,
      'status': 'open',
      'can_join': true,
      'is_public': true,
      'is_invite_only': false,
      'is_featured': featured,
      'featured_order': featured ? 1 : 0,
      'latitude': latitude,
      'longitude': longitude,
    };

    final matchRepository = MatchRepository(
      apiClient: ApiClient(
        baseUrl: 'https://example.test/api',
        tokenStore: SecureTokenStore(useMemoryOnly: true),
        httpClient: MockClient((request) async {
          requests.add(request.url);
          if (request.url.queryParameters['radius_miles'] == '50') {
            return http.Response(
              jsonEncode({'data': [
                record(20, city: 'Austin', latitude: 30.3,
                    longitude: -97.7431, featured: true),
                record(21, city: 'Austin', latitude: 30.4,
                    longitude: -97.7431),
              ]}),
              200,
            );
          }

          if (request.url.queryParameters['q'] == 'Austin') {
            return http.Response(
              jsonEncode({'data': [
                // This same-city match is beyond 50 miles and therefore can
                // only come from the independent city search.
                record(15, city: 'Austin', latitude: 31.6,
                    longitude: -97.7431, featured: true),
              ]}),
              200,
            );
          }

          if (request.url.queryParameters.isEmpty) {
            return http.Response(
              jsonEncode({'data': [
                record(90, city: 'Dallas', latitude: 32.77,
                    longitude: -96.79, featured: true),
              ]}),
              200,
            );
          }

          // The user's selected Home/Map filters target another city/radius.
          return http.Response('{"data":[]}', 200);
        }),
      ),
    );

    final discoveryStore = MatchDiscoveryStore();
    discoveryStore.update(MatchFilters.defaults().copyWith(
      selectedLocation: 'Boston',
      radiusMiles: 1,
      latitude: 42.3601,
      longitude: -71.0589,
    ));
    addTearDown(discoveryStore.dispose);

    final locations = _AustinLocationRepository();
    await tester.pumpWidget(MaterialApp(
      home: MainNavigationShell(
        matchRepository: matchRepository,
        discoveryStore: discoveryStore,
        locationRepository: locations,
        initialProfileData: ProfilePreviewData.currentUser.copyWith(
          city: 'Boston',
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final home = tester.widget<HomeScreen>(find.byType(HomeScreen));
    expect(home.data!.upcomingMatches.map((m) => m.id), ['20', '15', '21']);
    expect(home.data!.isShowingOtherCities, isFalse);
    expect(home.data!.nearbyMatches, isEmpty);
    expect(locations.locationReads, greaterThan(0));

    expect(requests.any((url) =>
      url.queryParameters['radius_miles'] == '50' &&
      url.queryParameters['latitude'] == '30.2672000' &&
      url.queryParameters['longitude'] == '-97.7431000' &&
      url.queryParameters['date_filter'] == 'any'), isTrue);
    expect(requests.any((url) =>
      url.queryParameters['radius_miles'] == '1' &&
      url.queryParameters['latitude'] == '42.3601000'), isTrue);
    expect(requests.any((url) =>
      url.queryParameters['q'] == 'Austin' &&
      !url.queryParameters.containsKey('radius_miles')), isTrue);

    // The pinned GPS/50-mile banner request does not change Map/Nearby filters.
    expect(discoveryStore.filters.radiusMiles, 1);
    expect(discoveryStore.filters.selectedLocation, 'Boston');
    expect(discoveryStore.filters.latitude, 42.3601);
    expect(tester.takeException(), isNull);
  });
}
