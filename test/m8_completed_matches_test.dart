import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mahj_app/app/app_assets.dart';
import 'package:mahj_app/core/network/api_client.dart';
import 'package:mahj_app/core/storage/token_store.dart';
import 'package:mahj_app/features/home/domain/home_match.dart';
import 'package:mahj_app/features/matches/data/match_repository.dart';
import 'package:mahj_app/features/matches/domain/match_score_player.dart';
import 'package:mahj_app/features/matches/presentation/match_completed_screen.dart';
import 'package:mahj_app/features/matches/presentation/my_matches_screen.dart';

void main() {
  test('M8 repository honors completion, score, and history contracts', () async {
    final tokenStore = SecureTokenStore(useMemoryOnly: true);
    await tokenStore.write('m8-test-token');

    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);

      if (request.method == 'GET' &&
          request.url.path == '/api/matches/77/completion') {
        return http.Response(
          jsonEncode(_completionPayload(scoresSubmitted: false)),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (request.method == 'POST' &&
          request.url.path == '/api/matches/77/scores') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['scores'], [
          {'player_id': 10, 'score': 21},
          {'player_id': 11, 'score': 18},
        ]);

        return http.Response(
          jsonEncode(_completionPayload(scoresSubmitted: true)),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (request.method == 'GET' &&
          request.url.path == '/api/my-matches') {
        expect(request.url.queryParameters['completed_page'], '1');
        expect(request.url.queryParameters['cancelled_page'], '1');

        return http.Response(
          jsonEncode({
            'upcoming': <dynamic>[],
            'created_by_me': <dynamic>[],
            'invites': <dynamic>[],
            'completed': [
              _matchJson(id: '77', status: 'completed'),
            ],
            'cancelled': [
              _matchJson(id: '78', status: 'cancelled'),
            ],
            'meta': {
              'per_page': 20,
              'upcoming': {'page': 1, 'has_more': false},
              'created_by_me': {'page': 1, 'has_more': false},
              'invites': {'page': 1, 'has_more': false},
              'completed': {'page': 1, 'has_more': false},
              'cancelled': {'page': 1, 'has_more': false},
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.Response('Not found', 404);
    });

    final apiClient = ApiClient(
      baseUrl: 'https://example.test/api',
      tokenStore: tokenStore,
      httpClient: client,
    );
    final repository = MatchRepository(apiClient: apiClient);

    final completion = await repository.fetchCompletion(
      '77',
      currentUserId: '10',
    );

    expect(completion.match.status, MatchStatus.completed);
    expect(completion.players, hasLength(2));
    expect(completion.players.first.isCurrentUser, isTrue);
    expect(completion.players.first.avatarUrl, 'https://example.test/a.png');
    expect(completion.scoresSubmitted, isFalse);
    expect(completion.canSubmitScores, isTrue);

    final submitted = await repository.submitScores(
      '77',
      {'10': 21, '11': 18},
      currentUserId: '10',
    );

    expect(submitted.scoresSubmitted, isTrue);
    expect(submitted.canSubmitScores, isFalse);
    expect(submitted.players.first.initialScore, 21);
    expect(submitted.players.last.initialScore, 18);

    final history = await repository.listMyMatches();

    expect(history.completed.single.match.id, '77');
    expect(history.completed.single.match.status, MatchStatus.completed);
    expect(history.cancelled.single.match.id, '78');
    expect(history.cancelled.single.match.status, MatchStatus.cancelled);

    expect(
      requests.every(
        (request) =>
            request.headers['Authorization'] == 'Bearer m8-test-token',
      ),
      isTrue,
    );
  });

  testWidgets('M8 completed screen submits numeric scores and shows success', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Map<String, int>? submittedScores;

    await tester.pumpWidget(
      MaterialApp(
        home: MatchCompletedScreen(
          match: HomeMatch(
            id: '77',
            sportName: 'Basketball',
            location: 'Multan, Punjab, Pakistan',
            startsAt: DateTime(2026, 10, 1, 18),
            currentPlayers: 2,
            maxPlayers: 4,
            status: MatchStatus.completed,
          ),
          players: const [
            MatchScorePlayer(
              id: '10',
              displayName: 'Current Player',
              avatarAsset: AppAssets.demoAvatarOne,
              isCurrentUser: true,
            ),
            MatchScorePlayer(
              id: '11',
              displayName: 'Other Player With A Longer Name',
              avatarAsset: AppAssets.demoAvatarTwo,
            ),
          ],
          inviterName: 'Host Player',
          onSubmitScores: (matchId, scores) async {
            expect(matchId, '77');
            submittedScores = scores;
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Match Completed'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Other Player With A Longer Name'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    final currentScore = find.byKey(const ValueKey('match-score-10'));
    final otherScore = find.byKey(const ValueKey('match-score-11'));
    await tester.ensureVisible(currentScore);
    await tester.enterText(currentScore, '21');
    await tester.ensureVisible(otherScore);
    await tester.enterText(otherScore, '18');

    final submitButton = find.text('Submit Scores');
    await tester.ensureVisible(submitButton);
    await tester.pump();
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(submittedScores, {'10': 21, '11': 18});
    expect(find.text('Scores Submitted Successfully!'), findsOneWidget);
    expect(find.text('Submit Scores'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('M8 My Matches exposes Completed and Cancelled tabs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: MyMatchesScreen()));
    await tester.pump();

    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);

    await tester.tap(find.text('Completed'));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('my-match-card-my-completed-1')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Map<String, dynamic> _completionPayload({required bool scoresSubmitted}) {
  return {
    'match': _matchJson(id: '77', status: 'completed'),
    'players': [
      {
        'id': '10',
        'name': 'Current Player',
        'avatar_url': 'https://example.test/a.png',
        'score': scoresSubmitted ? 21 : null,
      },
      {
        'id': '11',
        'name': 'Other Player',
        'avatar_url': null,
        'score': scoresSubmitted ? 18 : null,
      },
    ],
    'scores_submitted': scoresSubmitted,
    'can_submit_scores': !scoresSubmitted,
  };
}

Map<String, dynamic> _matchJson({
  required String id,
  required String status,
}) {
  return {
    'id': id,
    'name': 'Basketball',
    'sport_name': 'Basketball',
    'location': 'Multan, Punjab, Pakistan',
    'starts_at': '2026-10-01T13:00:00Z',
    'current_players': 2,
    'max_players': 4,
    'status': status,
    'host': {
      'id': '10',
      'name': 'Host Player',
      'avatar_url': 'https://example.test/host.png',
    },
    'is_joined': true,
    'is_host': id == '77',
    'can_join': false,
    'can_leave': false,
    'can_cancel': false,
    'can_complete': false,
    'completed_at': status == 'completed'
        ? '2026-10-01T14:00:00Z'
        : null,
  };
}
