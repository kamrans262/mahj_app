import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mahj_app/core/network/api_client.dart';
import 'package:mahj_app/core/storage/token_store.dart';
import 'package:mahj_app/features/notifications/data/notification_repository.dart';
import 'package:mahj_app/features/notifications/data/notification_store.dart';
import 'package:mahj_app/features/notifications/domain/mahj_notification.dart';

void main() {
  test(
    'M7 notification repository and store honor the backend contract',
    () async {
      final tokenStore = SecureTokenStore(useMemoryOnly: true);
      await tokenStore.write('m7-test-token');
  
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
  
        if (request.method == 'GET' &&
            request.url.path == '/api/notifications' &&
            request.url.queryParameters['page'] == '1') {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': '10',
                  'type': 'match_invite',
                  'title': 'Game Invitation',
                  'message': 'Austen invited you.',
                  'created_at': '2026-10-01T12:00:00Z',
                  'is_read': false,
                  'related_match_id': '44',
                  'related_user_id': '7',
                  'data': {'invitation_id': '81'},
              },
              {
                'id': '9',
                'type': 'chat_message',
                'title': 'New Message',
                'message': 'Jenny sent a message.',
                'created_at': '2026-10-01T11:00:00Z',
                'is_read': false,
                'related_match_id': '44',
                'related_user_id': '8',
                'data': {},
              },
            ],
            'meta': {
              'page': 1,
              'per_page': 20,
              'has_more': true,
              'unread_count': 2,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (request.method == 'GET' &&
          request.url.path == '/api/notifications' &&
          request.url.queryParameters['page'] == '2') {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': '8',
                'type': 'subscription_update',
                'title': 'Subscription Update',
                'message': 'Your subscription changed.',
                'created_at': '2026-10-01T10:00:00Z',
                'is_read': true,
                'related_match_id': null,
                'related_user_id': null,
                'data': {},
              },
            ],
            'meta': {
              'page': 2,
              'per_page': 20,
              'has_more': false,
              'unread_count': 2,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (request.method == 'PATCH' &&
          request.url.path == '/api/notifications/10/read') {
        return http.Response(
          jsonEncode({
            'notification': {
              'id': '10',
              'type': 'match_invite',
              'title': 'Game Invitation',
              'message': 'Austen invited you.',
              'created_at': '2026-10-01T12:00:00Z',
              'is_read': true,
              'related_match_id': '44',
              'related_user_id': '7',
              'data': {'invitation_id': '81'},
            },
            'unread_count': 1,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (request.method == 'GET' &&
          request.url.path == '/api/notifications/unread-count') {
        return http.Response(
          jsonEncode({'unread_count': 3}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (request.method == 'GET' &&
          request.url.path == '/api/notification-settings') {
        return http.Response(
          jsonEncode({
            'settings': {
              'new_games_nearby': true,
              'game_invitations': false,
              'players_joining_my_game': true,
              'game_confirmations': true,
              'game_reminders': false,
              'schedule_changes': true,
              'new_messages': true,
              'subscription_updates': false,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (request.method == 'PUT' &&
          request.url.path == '/api/notification-settings') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.keys.toSet(), {
          'new_games_nearby',
          'game_invitations',
          'players_joining_my_game',
          'game_confirmations',
          'game_reminders',
          'schedule_changes',
          'new_messages',
          'subscription_updates',
        });

        return http.Response(
          jsonEncode({'settings': body}),
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
    final repository = NotificationRepository(apiClient: apiClient);
    final store = NotificationStore(repository: repository);

    await store.refresh();

    expect(store.notifications, hasLength(2));
    expect(store.unreadCount, 2);
    expect(store.hasMore, isTrue);
    expect(store.notifications.first.type, MahjNotificationType.matchInvite);
    expect(store.notifications.first.relatedInvitationId, '81');

    await store.loadMore();

    expect(store.notifications, hasLength(3));
    expect(store.hasMore, isFalse);
    expect(
      store.notifications.last.type,
      MahjNotificationType.subscriptionUpdate,
    );

    final opened = await store.markRead(store.notifications.first);

    expect(opened.isRead, isTrue);
    expect(store.unreadCount, 1);
    expect(store.notifications.first.isRead, isTrue);

    await store.refreshUnreadCount();

    expect(store.unreadCount, 3);

    final settings = await repository.loadSettings();

    expect(settings.newGamesNearby, isTrue);
    expect(settings.gameInvitations, isFalse);
    expect(settings.gameReminders, isFalse);
    expect(settings.subscriptionUpdates, isFalse);

    final saved = await repository.saveSettings(
      settings.copyWith(
        gameInvitations: true,
        gameReminders: true,
        subscriptionUpdates: true,
      ),
    );

    expect(saved.gameInvitations, isTrue);
    expect(saved.gameReminders, isTrue);
    expect(saved.subscriptionUpdates, isTrue);

    expect(
      requests.every(
        (request) => request.headers['Authorization'] == 'Bearer m7-test-token',
      ),
      isTrue,
    );
    },
  );
}
