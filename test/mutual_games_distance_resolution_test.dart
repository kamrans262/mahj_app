import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mahj_app/core/network/api_client.dart';
import 'package:mahj_app/core/storage/token_store.dart';
import 'package:mahj_app/features/home/data/location_repository.dart';
import 'package:mahj_app/features/home/domain/discovery_location.dart';
import 'package:mahj_app/features/home/domain/home_match.dart';
import 'package:mahj_app/features/home/domain/match_filters.dart';
import 'package:mahj_app/features/matches/data/match_distance_resolver.dart';
import 'package:mahj_app/features/matches/data/match_repository.dart';

class _TokenStore implements TokenStore {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> read() async => 'test-token';

  @override
  Future<void> write(String token) async {}
}

ApiClient _apiClient() => ApiClient(
  baseUrl: 'https://example.test/api',
  tokenStore: _TokenStore(),
  httpClient: MockClient((_) async => http.Response('{}', 200)),
);

class _FakeLocations extends LocationRepository {
  _FakeLocations({
    this.grantedPosition,
    this.searchResults = const <DiscoveryLocation>[],
    this.permissionBlocked = false,
  }) : super(apiClient: _apiClient());

  final DiscoveryLocation? grantedPosition;
  final List<DiscoveryLocation> searchResults;
  final bool permissionBlocked;
  int searches = 0;
  int permissionRequests = 0;

  @override
  Future<DiscoveryLocation?> currentLocationIfGranted() async =>
      grantedPosition;

  @override
  Future<DiscoveryLocation> currentLocation() async {
    permissionRequests++;
    if (permissionBlocked || grantedPosition == null) {
      throw const LocationAccessException('Location permission unavailable');
    }
    return grantedPosition!;
  }

  @override
  Future<List<DiscoveryLocation>> search(String query) async {
    searches++;
    return searchResults;
  }
}

HomeMatch _sharedMatch({
  double? latitude,
  double? longitude,
  String address = 'Central Park, New York',
}) {
  return HomeMatch.fromJson({
    'id': '123',
    'sport_name': 'Mah Jongg',
    'location': address,
    'starts_at': '2026-12-10T17:00:00Z',
    'current_players': 2,
    'max_players': 4,
    'status': 'open',
    'latitude': latitude,
    'longitude': longitude,
  });
}

void main() {
  test('mutual match with coordinates gets device distance', () async {
    final locations = _FakeLocations(
      grantedPosition: const DiscoveryLocation.current(
        latitude: 40.785091,
        longitude: -73.968285,
      ),
    );
    final resolver = MatchDistanceResolver(
      repository: MatchRepository(apiClient: _apiClient()),
      locations: locations,
    );

    final result = await resolver.resolve(
      _sharedMatch(latitude: 40.785091, longitude: -73.968285),
    );

    expect(result.match.distanceMiles, closeTo(0, 0.0001));
    expect(result.distanceLabel, '0.0 miles');
    expect(locations.searches, 0);
  });

  test('historic mutual match with specific address gets estimated distance',
      () async {
    final locations = _FakeLocations(
      grantedPosition: const DiscoveryLocation.current(
        latitude: 40.785091,
        longitude: -73.968285,
      ),
      searchResults: const [
        DiscoveryLocation(
          label: 'Central Park, New York, NY',
          latitude: 40.785091,
          longitude: -73.968285,
        ),
      ],
    );
    final resolver = MatchDistanceResolver(
      repository: MatchRepository(apiClient: _apiClient()),
      locations: locations,
    );

    final result = await resolver.resolve(_sharedMatch());

    expect(result.match.hasCoordinates, isTrue);
    expect(result.match.distanceMiles, closeTo(0, 0.0001));
    expect(result.distanceLabel, 'About 0.0 miles');
    expect(locations.searches, 1);
  });

  test('ambiguous historical venues do not get false location data',
      () async {
    final locations = _FakeLocations(
      searchResults: const [
        DiscoveryLocation(
          label: 'Community Hall, A Different City',
          latitude: 30,
          longitude: 70,
        ),
      ],
    );
    final resolver = MatchDistanceResolver(
      repository: MatchRepository(apiClient: _apiClient()),
      locations: locations,
    );

    final result = await resolver.resolve(
      _sharedMatch(address: 'Community Hall'),
    );

    expect(result.match.distanceMiles, isNull);
    expect(result.distanceLabel, 'Match location not mapped');
    expect(locations.searches, 0);
  });

  test('specific address must match the locality of the geocoder result',
      () async {
    final locations = _FakeLocations(
      searchResults: const [
        DiscoveryLocation(
          label: 'Central Park, Lahore',
          latitude: 31.5,
          longitude: 74.3,
        ),
      ],
    );
    final resolver = MatchDistanceResolver(
      repository: MatchRepository(apiClient: _apiClient()),
      locations: locations,
    );

    final result = await resolver.resolve(_sharedMatch());

    expect(result.distanceLabel, 'Match location not mapped');
    expect(result.match.distanceMiles, isNull);
  });

  test('mutual match uses selected location when GPS is unavailable',
      () async {
    final locations = _FakeLocations(permissionBlocked: true);
    final resolver = MatchDistanceResolver(
      repository: MatchRepository(apiClient: _apiClient()),
      locations: locations,
    );

    final result = await resolver.resolve(
      _sharedMatch(latitude: 40.785091, longitude: -73.968285),
      selectedFilters: MatchFilters.defaults().copyWith(
        selectedLocation: 'Central Park, New York',
        latitude: 40.785091,
        longitude: -73.968285,
      ),
    );

    expect(result.match.distanceMiles, closeTo(0, 0.0001));
    expect(result.distanceLabel, '0.0 miles from selected location');
    expect(locations.permissionRequests, 0);
  });

  test('mutual match explains unavailable GPS instead of inventing distance',
      () async {
    final locations = _FakeLocations(permissionBlocked: true);
    final resolver = MatchDistanceResolver(
      repository: MatchRepository(apiClient: _apiClient()),
      locations: locations,
    );

    final result = await resolver.resolve(
      _sharedMatch(latitude: 40.785091, longitude: -73.968285),
    );

    expect(result.match.distanceMiles, isNull);
    expect(result.distanceLabel, 'Enable location to see distance');
    expect(locations.permissionRequests, 1);
  });
}
