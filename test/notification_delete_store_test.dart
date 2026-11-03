import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mahj_app/core/network/api_client.dart';
import 'package:mahj_app/core/storage/token_store.dart';
import 'package:mahj_app/features/notifications/data/notification_repository.dart';
import 'package:mahj_app/features/notifications/data/notification_store.dart';

void main() {
  test('Delete calls authenticated API, removes only target, and updates unread badge', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.method == 'DELETE' && request.url.path == '/api/notifications/1') {
        return http.Response(
          jsonEncode({'message': 'Notification deleted.', 'unread_count': 0}),
          200,
        );
      }
      if (request.method == 'GET' && request.url.path == '/api/notifications') {
        return http.Response(jsonEncode({
          'data': [
            {
              'id': '1',
              'type': 'nearby_match',
              'title': 'New Match Nearby',
              'message': 'A match is available',
              'created_at': DateTime.now().toUtc().toIso8601String(),
              'is_read': false,
            },
            {
              'id': '2',
              'type': 'nearby_match',
              'title': 'An older update',
              'message': 'Details',
              'created_at': DateTime.now().toUtc().toIso8601String(),
              'is_read': true,
            },
          ],
          'meta': {'page': 1, 'has_more': false, 'unread_count': 1},
        }), 200);
      }
      return http.Response('{"message":"Not found"}', 404);
    });

    final store = NotificationStore(repository: NotificationRepository(
      apiClient: ApiClient(
        baseUrl: 'https://example.test/api',
        tokenStore: SecureTokenStore(useMemoryOnly: true),
        httpClient: client,
      ),
    ));
    addTearDown(store.dispose);

    await store.refresh();
    expect(store.notifications.map((item) => item.id), ['1', '2']);
    expect(store.unreadCount, 1);

    await store.deleteNotification(store.notifications.first);

    expect(requests.any((request) =>
        request.method == 'DELETE' &&
        request.url.path == '/api/notifications/1'), isTrue);
    expect(store.notifications.map((item) => item.id), ['2']);
    expect(store.unreadCount, 0);
  });

  test('Failed server deletion keeps notification and unread count unchanged', () async {
    final client = MockClient((request) async {
      if (request.method == 'DELETE') {
        return http.Response('{"message":"Server error"}', 500);
      }
      return http.Response(jsonEncode({
        'data': [
          {
            'id': '7',
            'type': 'nearby_match',
            'title': 'New Match Nearby',
            'message': 'Open match',
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'is_read': false,
          },
        ],
        'meta': {'page': 1, 'has_more': false, 'unread_count': 1},
      }), 200);
    });

    final store = NotificationStore(repository: NotificationRepository(
      apiClient: ApiClient(
        baseUrl: 'https://example.test/api',
        tokenStore: SecureTokenStore(useMemoryOnly: true),
        httpClient: client,
      ),
    ));
    addTearDown(store.dispose);
    await store.refresh();

    await expectLater(
      store.deleteNotification(store.notifications.single),
      throwsException,
    );

    expect(store.notifications.single.id, '7');
    expect(store.unreadCount, 1);
  });
}
