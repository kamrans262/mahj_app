import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mahj_app/core/network/api_client.dart';
import 'package:mahj_app/core/storage/token_store.dart';
import 'package:mahj_app/features/home/domain/home_match.dart';
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
  test('host edit sends PUT without losing privacy and returns refreshed match', () async {
    final client = MockClient((request) async {
      expect(request.method, 'PUT');
      expect(request.url.path, '/api/matches/42');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['location_address'], 'New Community Hall');
      expect(body['venue_name'], 'Updated Venue');
      expect(body['notes'], 'Updated notes');
      expect(body['is_invite_only'], true);
      expect(body['is_public'], false);
      return http.Response(jsonEncode({
        'match': {
          'id': '42',
          'name': 'Mah Jongg',
          'location': 'New Community Hall',
          'venue_name': 'Updated Venue',
          'notes': 'Updated notes',
          'starts_at': '2026-12-01T12:00:00Z',
          'current_players': 2,
          'max_players': 4,
          'status': 'open',
          'is_public': false,
          'is_invite_only': true,
          'is_host': true,
        },
      }), 200);
    });
    final repository = MatchRepository(apiClient: ApiClient(
      baseUrl: 'https://example.com/api',
      tokenStore: _MemoryTokenStore(),
      httpClient: client,
    ));
    final updated = await repository.update('42', CreateMatchRequest(
      sportName: 'Mah Jongg',
      sportIconKey: 'generic',
      locationAddress: 'New Community Hall',
      venueName: 'Updated Venue',
      notes: 'Updated notes',
      startsAt: DateTime.utc(2026, 12, 1, 12),
      isPublicMatch: false,
      isInviteOnly: true,
    ));
    expect(updated.venueName, 'Updated Venue');
    expect(updated.isInviteOnly, isTrue);
    expect(updated.isOwnedByCurrentUser, isTrue);
  });


  test('loads managed sports catalog', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/sports');

      return http.Response(
        jsonEncode({
          'data': [
            {
              'id': 1,
              'name': 'American Football',
              'slug': 'american-football',
              'icon_key': 'football',
            },
            {
              'id': 2,
              'name': 'Basketball',
              'slug': 'basketball',
              'icon_key': 'basketball',
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

    final sports = await repository.listSports();

    expect(sports, hasLength(2));
    expect(sports.first.name, 'American Football');
    expect(sports.first.iconKey, 'football');
    expect(sports.last.id, 2);
  });

  test('creates a four-player match and maps sport icon state', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/matches');
      expect(request.headers['authorization'], 'Bearer test-token');

      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['sport_id'], 2);
      expect(body['custom_sport_name'], isNull);
      expect(body['name'], 'Basketball');
      expect(body['location_address'], 'Central Park');
      expect(body['notes'], 'Bring water.');
      expect(body['is_public'], isTrue);
      expect(body['is_invite_only'], isFalse);

      return http.Response(
        jsonEncode({
          'match': {
            'id': '41',
            'name': 'Basketball',
            'sport_name': 'Basketball',
            'sport_icon_key': 'basketball',
            'sport': {
              'id': '2',
              'name': 'Basketball',
              'slug': 'basketball',
              'icon_key': 'basketball',
            },
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
        sportId: 2,
        sportName: 'Basketball',
        sportSlug: 'basketball',
        sportIconKey: 'basketball',
        locationAddress: 'Central Park',
        venueName: 'Court 1',
        notes: 'Bring water.',
        startsAt: DateTime.utc(2026, 10, 1, 18),
        isPublicMatch: true,
        isInviteOnly: false,
      ),
    );

    expect(match.id, '41');
    expect(match.sportName, 'Basketball');
    expect(match.sportIconKey, 'basketball');
    expect(match.currentPlayers, 1);
    expect(match.maxPlayers, 4);
    expect(match.isOwnedByCurrentUser, isTrue);
    expect(match.isCurrentUserJoined, isTrue);
    expect(match.canCancel, isTrue);
  });

  test('Other sends custom sport without sport id', () async {
    final client = MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['sport_id'], isNull);
      expect(body['custom_sport_name'], 'Ultimate Frisbee');

      return http.Response(
        jsonEncode({
          'match': {
            'id': '55',
            'sport_name': 'Ultimate Frisbee',
            'sport_icon_key': 'generic',
            'location': 'Central Park',
            'starts_at': '2026-10-01T18:00:00.000000Z',
            'current_players': 1,
            'max_players': 4,
            'status': 'open',
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
        customSportName: 'Ultimate Frisbee',
        sportName: 'Ultimate Frisbee',
        sportIconKey: 'generic',
        locationAddress: 'Central Park',
        startsAt: DateTime.utc(2026, 10, 1, 18),
        isPublicMatch: true,
        isInviteOnly: false,
      ),
    );

    expect(match.sportName, 'Ultimate Frisbee');
    expect(match.sportIconKey, 'generic');
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
            'sport_icon_key': 'basketball',
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

  test('created match with map coordinates gains a real distance when details open', () {
    final repository = MatchRepository(
      apiClient: ApiClient(
        baseUrl: 'https://example.com/api',
        tokenStore: _MemoryTokenStore(),
        httpClient: MockClient((_) async => throw StateError('No HTTP needed')),
      ),
    );
    final created = HomeMatch.fromJson({
      'id': '91',
      'sport_name': 'Mah Jongg',
      'location': 'Central Park',
      'starts_at': '2026-12-01T18:00:00Z',
      'current_players': 1,
      'max_players': 4,
      'status': 'open',
      'latitude': 40.785091,
      'longitude': -73.968285,
    });

    expect(created.distanceMiles, isNull);
    final resolved = repository.withDistanceFromOrigin(
      created,
      latitude: 40.785091,
      longitude: -73.968285,
    );
    expect(resolved.distanceMiles, closeTo(0, 0.0001));

    final noCoordinates = created.copyWith(
      latitude: null,
      longitude: null,
    );
    // The model's copyWith retains null coordinates; use a fresh API object
    // to check that missing coordinates never produce a made-up distance.
    final missingLocation = HomeMatch.fromJson({
      'id': '92',
      'sport_name': 'Mah Jongg',
      'location': 'Unresolved Venue',
      'starts_at': '2026-12-01T18:00:00Z',
      'current_players': 1,
      'max_players': 4,
      'status': 'open',
    });
    expect(noCoordinates.hasCoordinates, isTrue);
    expect(
      repository.withDistanceFromOrigin(
        missingLocation,
        latitude: 40.785091,
        longitude: -73.968285,
      ).distanceMiles,
      isNull,
    );
  });
}
