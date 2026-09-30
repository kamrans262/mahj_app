import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mahj_app/core/network/api_client.dart';
import 'package:mahj_app/core/storage/token_store.dart';
import 'package:mahj_app/features/home/domain/match_filters.dart';
import 'package:mahj_app/features/matches/data/match_repository.dart';

class _MemoryTokenStore implements TokenStore {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> read() async => 'test-token';

  @override
  Future<void> write(String token) async {}
}

void main() {
  test('discovery list sends filters and maps backend distance', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/matches');
      expect(request.url.queryParameters['latitude'], '40.7850910');
      expect(request.url.queryParameters['longitude'], '-73.9682850');
      expect(request.url.queryParameters['radius_miles'], '8');
      expect(request.url.queryParameters['date_filter'], 'next_3_days');
      expect(request.url.queryParameters['open_spots_only'], '1');
      expect(request.url.queryParameters['sort'], 'distance');
      expect(request.url.queryParameters['discover_only'], '1');
      expect(request.url.queryParameters['q'], 'basketball');

      return http.Response(
        jsonEncode({
          'data': [
            {
              'id': '12',
              'sport_name': 'Basketball',
              'location': 'Central Park, New York, NY',
              'starts_at': '2026-10-01T18:00:00.000000Z',
              'current_players': 2,
              'max_players': 4,
              'status': 'open',
              'latitude': 40.785091,
              'longitude': -73.968285,
              'distance_miles': 1.24,
              'can_join': true,
              'is_joined': false,
              'is_host': false,
              'can_leave': false,
              'can_cancel': false,
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final repository = MatchRepository(
      apiClient: ApiClient(
        baseUrl: 'https://example.com/api',
        tokenStore: _MemoryTokenStore(),
        httpClient: client,
      ),
    );

    final filters = MatchFilters.defaults().copyWith(
      selectedLocation: 'Central Park, New York, NY',
      radiusMiles: 8,
      dateFilter: MatchDateFilter.nextThreeDays,
      latitude: 40.785091,
      longitude: -73.968285,
    );

    final matches = await repository.list(
      filters: filters,
      query: 'basketball',
      discoverOnly: true,
    );

    expect(matches, hasLength(1));
    expect(matches.first.distanceMiles, 1.24);
    expect(matches.first.hasCoordinates, isTrue);
  });
}
