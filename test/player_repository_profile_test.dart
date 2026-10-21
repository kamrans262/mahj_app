import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mahj_app/core/network/api_client.dart';
import 'package:mahj_app/core/storage/token_store.dart';
import 'package:mahj_app/features/profile/data/player_repository.dart';

class _TokenStore implements TokenStore {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> read() async => 'test-token';
  @override
  Future<void> write(String token) async {}
}

void main() {
  test('other player profile uses server registration year and mutual games', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.headers['authorization'], 'Bearer test-token');
      expect(request.url.path, '/api/users/24/profile');
      expect(request.url.queryParameters['per_page'], '2');
      return http.Response(jsonEncode({
        'player': {
          'id': '24',
          'name': 'Test Player',
          'avatar_url': null,
          'matches_played': 3,
          'matches_hosted': 1,
          'attendance_percent': 80,
          'member_since_year': 2024,
          'mutual_games_total': 1,
        },
        'mutual_games': [{
          'id': '100',
          'name': 'Mah Jongg',
          'location': 'Central Park',
          'starts_at': '2026-12-01T12:00:00Z',
          'current_players': 2,
          'max_players': 4,
          'status': 'open',
        }],
        'meta': {'page': 1, 'has_more': false},
      }), 200);
    });
    final repository = PlayerRepository(apiClient: ApiClient(
      baseUrl: 'https://example.com/api',
      tokenStore: _TokenStore(),
      httpClient: client,
    ));

    final player = await repository.fetchProfile('24');
    expect(player.name, 'Test Player');
    expect(player.memberSinceLabel, '2024');
    expect(player.email, isEmpty);
    expect(player.addressLine, isEmpty);
    expect(player.mutualGamesTotal, 1);
    expect(player.mutualGames.single.id, '100');
  });

  test('View All requests actual shared games in paginated batches', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/users/24/profile');
      expect(request.url.queryParameters['page'], '2');
      expect(request.url.queryParameters['per_page'], '20');
      return http.Response(jsonEncode({
        'mutual_games': [{
          'id': '102',
          'name': 'Mah Jongg',
          'location': 'Shared Hall',
          'starts_at': '2026-12-02T12:00:00Z',
          'current_players': 2,
          'max_players': 4,
          'status': 'confirmed',
        }],
        'meta': {'page': 2, 'has_more': false},
      }), 200);
    });
    final repository = PlayerRepository(apiClient: ApiClient(
      baseUrl: 'https://example.com/api',
      tokenStore: _TokenStore(),
      httpClient: client,
    ));
    final result = await repository.fetchMutualGames('24', page: 2);
    expect(result.games.single.id, '102');
    expect(result.hasMore, false);
  });
}
