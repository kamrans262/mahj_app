import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mahj_app/core/network/api_client.dart';
import 'package:mahj_app/core/storage/token_store.dart';
import 'package:mahj_app/features/home/domain/home_match.dart';
import 'package:mahj_app/features/matches/data/match_repository.dart';
import 'package:mahj_app/features/profile/data/player_repository.dart';
import 'package:mahj_app/features/profile/domain/favorite_player.dart';
import 'package:mahj_app/features/profile/presentation/favorites_screen.dart';

class _TokenStore implements TokenStore {
  @override
  Future<String?> read() async => 'test-token';
  @override
  Future<void> write(String token) async {}
  @override
  Future<void> clear() async {}
}

void main() {
  test('FavoritePlayer card displays mutual game count, not all joined games', () {
    const player = FavoritePlayer(
      id: '6',
      name: 'Player',
      username: 'player',
      gamesCount: 2,
    );
    expect(player.secondaryLabel, '2 mutual games');
    const one = FavoritePlayer(
      id: '7',
      name: 'Other Player',
      username: 'other',
      gamesCount: 1,
    );
    expect(one.secondaryLabel, '1 mutual game');
  });

  testWidgets('By Match hides ended and cancelled saved games without deleting them', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final futureDate = DateTime.now().add(const Duration(days: 2)).toUtc();
    final pastDate = DateTime.now().subtract(const Duration(days: 2)).toUtc();
    Map<String, dynamic> match(
      String id,
      String status,
      DateTime date,
    ) => {
      'id': id,
      'name': 'Mah Jongg',
      'sport_name': 'Mah Jongg',
      'location': 'Community Hall',
      'starts_at': date.toIso8601String(),
      'current_players': 2,
      'max_players': 4,
      'status': status,
    };

    final client = MockClient((request) async {
      if (request.url.path == '/api/favorites') {
        return http.Response(jsonEncode({
          'data': [
            match('1', 'open', futureDate),
            match('2', 'open', pastDate),
            match('3', 'completed', pastDate),
            match('4', 'cancelled', futureDate),
            match('5', 'confirmed', futureDate),
          ],
        }), 200);
      }
      if (request.url.path == '/api/favorite-players') {
        return http.Response(jsonEncode({
          'data': [{
            'id': '6',
            'name': 'Player',
            'mutual_games_count': 2,
            'games_count': 10,
          }],
        }), 200);
      }
      return http.Response('{}', 404);
    });

    final api = ApiClient(
      baseUrl: 'https://example.com/api',
      tokenStore: _TokenStore(),
      httpClient: client,
    );
    await tester.pumpWidget(MaterialApp(
      home: FavoritesScreen(
        matchRepository: MatchRepository(apiClient: api),
        playerRepository: PlayerRepository(apiClient: api),
        onMatchTap: (HomeMatch match) async {},
        onPlayerTap: (FavoritePlayer player) async {},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('favorite-match-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('favorite-match-5')), findsOneWidget);
    expect(find.byKey(const ValueKey('favorite-match-2')), findsNothing);
    expect(find.byKey(const ValueKey('favorite-match-3')), findsNothing);
    expect(find.byKey(const ValueKey('favorite-match-4')), findsNothing);

    await tester.tap(find.text('By Player'));
    await tester.pumpAndSettle();
    expect(find.text('2 mutual games'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
