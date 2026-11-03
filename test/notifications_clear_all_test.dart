import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mahj_app/core/network/api_client.dart';
import 'package:mahj_app/core/storage/token_store.dart';
import 'package:mahj_app/features/notifications/data/notification_repository.dart';
import 'package:mahj_app/features/notifications/data/notification_store.dart';
import 'package:mahj_app/features/notifications/domain/mahj_notification.dart';
import 'package:mahj_app/features/notifications/presentation/notifications_screen.dart';

MahjNotification _item(String id, {bool read = false}) => MahjNotification(
  id: id,
  type: MahjNotificationType.nearbyMatch,
  title: 'New Match Nearby',
  message: 'A game is available.',
  createdAt: DateTime.now(),
  isRead: read,
);

void _phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('Clear All stays small and right aligned, and waits for success', (
    tester,
  ) async {
    _phoneSize(tester);
    final clearing = Completer<void>();
    var calls = 0;

    await tester.pumpWidget(MaterialApp(
      home: NotificationsScreen(
        notifications: [_item('one'), _item('two', read: true)],
        onClearAll: () {
          calls++;
          return clearing.future;
        },
      ),
    ));

    final clear = find.byKey(const ValueKey('notifications-clear-all'));
    expect(clear, findsOneWidget);
    expect(find.text('Clear All'), findsOneWidget);
    final text = tester.widget<Text>(find.text('Clear All'));
    expect(text.style?.fontSize, 12);
    expect(tester.takeException(), isNull);

    await tester.tap(clear);
    await tester.pump();

    expect(calls, 1);
    expect(find.text('Clearing...'), findsOneWidget);
    expect(find.byKey(const ValueKey('notification-item-one')),
        findsOneWidget);

    clearing.complete();
    await tester.pumpAndSettle();

    expect(find.text('No notifications yet'), findsOneWidget);
    expect(find.byKey(const ValueKey('notification-item-one')), findsNothing);
    expect(clear, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Clear All failure preserves all existing notifications', (
    tester,
  ) async {
    _phoneSize(tester);
    await tester.pumpWidget(MaterialApp(
      home: NotificationsScreen(
        notifications: [_item('one')],
        onClearAll: () async => throw Exception('Network error'),
      ),
    ));
    await tester.tap(find.byKey(const ValueKey('notifications-clear-all')));
    await tester.pump();

    expect(find.byKey(const ValueKey('notification-item-one')),
        findsOneWidget);
    expect(find.text('Clear All'), findsOneWidget);
    expect(find.text('Could not clear notifications. Please try again.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Clear All sends one authenticated delete and resets list and badge', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.method == 'DELETE' &&
          request.url.path == '/api/notifications') {
        return http.Response(jsonEncode({
          'message': 'All notifications cleared.',
          'deleted_count': 2,
          'unread_count': 0,
        }), 200);
      }
      return http.Response(jsonEncode({
        'data': [
          {
            'id': 'one',
            'type': 'nearby_match',
            'title': 'New Match Nearby',
            'message': 'A game is available.',
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'is_read': false,
          },
          {
            'id': 'two',
            'type': 'nearby_match',
            'title': 'A read update',
            'message': 'More details.',
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'is_read': true,
          },
        ],
        'meta': {
          'page': 1,
          'unread_count': 1,
          'has_more': true,
        },
      }), 200);
    });

    final store = NotificationStore(
      repository: NotificationRepository(
        apiClient: ApiClient(
          baseUrl: 'https://example.test/api',
          tokenStore: SecureTokenStore(useMemoryOnly: true),
          httpClient: client,
        ),
      ),
    );
    addTearDown(store.dispose);

    await store.refresh();
    expect(store.notifications, hasLength(2));
    expect(store.unreadCount, 1);
    expect(store.hasMore, true);

    await store.clearAllNotifications();

    expect(
      requests.where((request) =>
          request.method == 'DELETE' &&
          request.url.path == '/api/notifications').length,
      1,
    );
    expect(store.notifications, isEmpty);
    expect(store.unreadCount, 0);
    expect(store.hasMore, false);
  });

  test('Clear All server error does not lose notification history', () async {
    final client = MockClient((request) async {
      if (request.method == 'DELETE') {
        return http.Response('{"message":"Server error"}', 500);
      }
      return http.Response(jsonEncode({
        'data': [
          {
            'id': 'one',
            'type': 'nearby_match',
            'title': 'New Match Nearby',
            'message': 'A game is available.',
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'is_read': false,
          },
        ],
        'meta': {'page': 1, 'unread_count': 1, 'has_more': false},
      }), 200);
    });

    final store = NotificationStore(
      repository: NotificationRepository(
        apiClient: ApiClient(
          baseUrl: 'https://example.test/api',
          tokenStore: SecureTokenStore(useMemoryOnly: true),
          httpClient: client,
        ),
      ),
    );
    addTearDown(store.dispose);
    await store.refresh();

    await expectLater(store.clearAllNotifications(), throwsException);
    expect(store.notifications.single.id, 'one');
    expect(store.unreadCount, 1);
    expect(store.isClearingAll, false);
  });
}
