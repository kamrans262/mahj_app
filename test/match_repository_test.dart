import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mahj_app/core/network/api_client.dart';
import 'package:mahj_app/core/storage/token_store.dart';
import 'package:mahj_app/features/matches/data/match_repository.dart';
import 'package:mahj_app/features/matches/domain/create_match_form_state.dart';

class _MemoryTokenStore implements TokenStore {
  String? token = 'test-token';

  @override
  Future<void> clear() async => token = null;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async => this.token = token;
}

void main() {
  test('creates a four-player match and maps host state', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/matches');
      expect(request.headers['authorization'], 'Bearer test-token');

      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['location_address'], 'Central Park');
      expect(body['is_public'], isTrue);
      expect(body['is_invite_only'], isFalse);

      return http.Response(
        jsonEncode({
          'match': {
            'id': '41',
            'sport_name': 'Basketball',
            'location': 'Central Park',
            'venue_name': 'Court 1',
            'starts_at': '2026-10-01T18:00:00.000000Z',
            'current_players': 1,
            'max_players': 4,
            'status': 'open',
            'is_public': true,
            'is_invite_only': false,
            'host': {'id': '7', 'name': 'Host User'},
            'is_joined': true,
            'is_host': true,
            'can_join': false,
            'can_leave': false,
            'can_cancel': true,
          },
        }),
        201,
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

    final match = await repository.create(
      CreateMatchRequest(
        locationAddress: 'Central Park',
        venueName: 'Court 1',
        startsAt: DateTime.utc(2026, 10, 1, 18),
        isPublicMatch: true,
        isInviteOnly: false,
      ),
    );

    expect(match.id, '41');
    expect(match.currentPlayers, 1);
    expect(match.maxPlayers, 4);
    expect(match.isOwnedByCurrentUser, isTrue);
    expect(match.isCurrentUserJoined, isTrue);
    expect(match.canCancel, isTrue);
  });

  test('join maps confirmed state when the fourth player joins', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/matches/41/join');

      return http.Response(
        jsonEncode({
          'match': {
            'id': '41',
            'sport_name': 'Basketball',
            'location': 'Central Park',
            'starts_at': '2026-10-01T18:00:00.000000Z',
            'current_players': 4,
            'max_players': 4,
            'status': 'confirmed',
            'host': {'id': '7', 'name': 'Host User'},
            'is_joined': true,
            'is_host': false,
            'can_join': false,
            'can_leave': true,
            'can_cancel': false,
          },
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

    final match = await repository.join('41');

    expect(match.status.name, 'confirmed');
    expect(match.currentPlayers, 4);
    expect(match.isCurrentUserJoined, isTrue);
    expect(match.canLeave, isTrue);
    expect(match.isFull, isTrue);
  });
}
