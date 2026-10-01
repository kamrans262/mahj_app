import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mahj_app/app/app_assets.dart';
import 'package:mahj_app/core/network/api_client.dart';
import 'package:mahj_app/core/storage/token_store.dart';
import 'package:mahj_app/features/profile/data/player_profile_preview_data.dart';
import 'package:mahj_app/features/profile/presentation/player_profile_screen.dart';
import 'package:mahj_app/features/settings/data/privacy_safety_repository.dart';
import 'package:mahj_app/features/settings/domain/privacy_safety_data.dart';
import 'package:mahj_app/features/settings/presentation/privacy_safety_screen.dart';

Future<void> _scrollTo(
  WidgetTester tester,
  Finder target,
  Finder scrollView,
) async {
  for (var attempt = 0; attempt < 8 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollView, const Offset(0, -280));
    await tester.pump();
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pump();
}

void main() {
  test('M9 repository loads safety state and sends moderation actions', () async {
    final tokenStore = SecureTokenStore(useMemoryOnly: true);
    await tokenStore.write('m9-token');

    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);

      if (request.method == 'GET' && request.url.path == '/api/safety') {
        return http.Response(
          jsonEncode({
            'blocked_users': [
              {
                'id': '12',
                'name': 'Blocked Player',
                'username': 'blocked.player',
                'avatar_url': 'https://example.test/avatar.png',
                'games_count': 38,
              },
            ],
            'report_history': [
              {
                'id': '90',
                'status': 'pending',
                'reason': 'safety_concern',
                'created_at': '2026-10-02T10:00:00Z',
                'reported_user': {
                  'id': '13',
                  'name': 'Reported Player',
                  'username': 'reported.player',
                  'avatar_url': null,
                  'games_count': 24,
                },
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (request.method == 'POST' &&
          request.url.path == '/api/users/13/report') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['reason_id'], 'safety_concern');
        expect(body['notes'], 'Unsafe conduct.');
        return http.Response(
          jsonEncode({'message': 'Report submitted.', 'status': 'pending'}),
          201,
          headers: {'content-type': 'application/json'},
        );
      }

      if (request.method == 'POST' &&
          request.url.path == '/api/users/13/block') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['reason_id'], 'safety_concern');
        return http.Response(
          jsonEncode({'message': 'Player blocked.', 'blocked': true}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (request.method == 'DELETE' &&
          request.url.path == '/api/users/12/block') {
        return http.Response(
          jsonEncode({'message': 'Player unblocked.', 'blocked': false}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.Response('Not found', 404);
    });

    final repository = PrivacySafetyRepository(
      apiClient: ApiClient(
        baseUrl: 'https://example.test/api',
        tokenStore: tokenStore,
        httpClient: client,
      ),
    );

    final data = await repository.load();
    expect(data.blockedUsers, hasLength(1));
    expect(data.blockedUsers.single.id, '12');
    expect(data.blockedUsers.single.secondaryLabel, '@blocked.player · 38 games');
    expect(data.reportHistory, hasLength(1));
    expect(data.reportHistory.single.status, PrivacyReportStatus.pending);

    await repository.reportPlayer(
      playerId: '13',
      reasonId: 'safety_concern',
      notes: 'Unsafe conduct.',
    );
    await repository.blockPlayer(
      playerId: '13',
      reasonId: 'safety_concern',
    );
    await repository.unblockPlayer('12');

    expect(
      requests.every(
        (request) => request.headers['Authorization'] == 'Bearer m9-token',
      ),
      isTrue,
    );
  });

  testWidgets('M9 unblock requires confirmation and updates the visible list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const blocked = PrivacySafetyUser(
      id: '12',
      displayName: 'Blocked Player',
      username: 'blocked.player',
      gamesCount: 38,
      avatarAsset: AppAssets.demoAvatarOne,
    );

    String? unblockedId;
    await tester.pumpWidget(
      MaterialApp(
        home: PrivacySafetyScreen(
          blockedUsers: const [blocked],
          rules: privacySafetyRules,
          reportHistory: const [],
          onUnblock: (playerId) async {
            unblockedId = playerId;
            return true;
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('privacy-unblock-12')));
    await tester.pumpAndSettle();

    expect(find.text('Unblock Blocked Player?'), findsOneWidget);
    expect(unblockedId, isNull);

    await tester.tap(
      find.byKey(const ValueKey('confirmation-confirm-button')),
    );
    await tester.pumpAndSettle();

    expect(unblockedId, '12');
    expect(find.text('No blocked users'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('M9 successful block updates player actions immediately', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var blockCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PlayerProfileScreen(
          player: PlayerProfilePreviewData.demo,
          onSendInvite: () {},
          onSubmitReport: (_) async => true,
          onSubmitBlock: (_) async {
            blockCalls++;
            return true;
          },
        ),
      ),
    );
    await tester.pump();

    final scroll = find.byKey(const ValueKey('player-profile-scroll-view'));
    final blockButton = find.byKey(const ValueKey('player-profile-block'));
    await _scrollTo(tester, blockButton, scroll);
    await tester.tap(blockButton);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('block-reason-field')));
    await tester.pumpAndSettle();

    final reason = find.byKey(
      const ValueKey('report-reason-option-safety_concern'),
    );
    await tester.ensureVisible(reason);
    await tester.tap(reason);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('block-submit-button')));
    await tester.pumpAndSettle();

    expect(blockCalls, 1);
    expect(find.byKey(const ValueKey('player-profile-block')), findsNothing);
    expect(
      find.byKey(const ValueKey('player-profile-send-invite')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('player-profile-report')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
