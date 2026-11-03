import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/notifications/domain/mahj_notification.dart';
import 'package:mahj_app/features/notifications/presentation/notifications_screen.dart';

MahjNotification _notification(String id, {bool isRead = false}) {
  return MahjNotification(
    id: id,
    type: MahjNotificationType.nearbyMatch,
    title: 'New Match Nearby',
    message: 'Open match in your area',
    createdAt: DateTime.now(),
    isRead: isRead,
  );
}

void main() {
  testWidgets('Swipe left reveals a circular delete action but does not delete', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var deletes = 0;
    await tester.pumpWidget(MaterialApp(
      home: NotificationsScreen(
        notifications: [_notification('one')],
        onDelete: (notification) async {
          deletes++;
        },
      ),
    ));

    final item = find.byKey(const ValueKey('notification-item-one'));
    final leftBefore = tester.getTopLeft(item).dx;

    await tester.drag(item, const Offset(-140, 0));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(item).dx, lessThan(leftBefore));
    expect(deletes, 0);
    expect(item, findsOneWidget);
    expect(find.byKey(const ValueKey('notification-delete-button')),
        findsOneWidget);

    await tester.drag(item, const Offset(140, 0));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(item).dx, closeTo(leftBefore, 0.1));
    expect(deletes, 0);
    expect(item, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Only tapping revealed delete permanently removes that row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final deleting = Completer<void>();
    final removed = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: NotificationsScreen(
        notifications: [
          _notification('delete-me'),
          _notification('keep-me', isRead: true),
        ],
        onDelete: (notification) {
          removed.add(notification.id);
          return deleting.future;
        },
      ),
    ));

    final item = find.byKey(const ValueKey('notification-item-delete-me'));
    await tester.drag(item, const Offset(-130, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('notification-delete-button')).first);
    await tester.pump();

    expect(removed, ['delete-me']);
    expect(item, findsOneWidget); // Backend has not confirmed yet.
    expect(find.byKey(const ValueKey('notification-item-keep-me')), findsOneWidget);

    deleting.complete();
    await tester.pumpAndSettle();

    expect(item, findsNothing);
    expect(find.byKey(const ValueKey('notification-item-keep-me')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Backend delete failure leaves the notification intact', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: NotificationsScreen(
        notifications: [_notification('fails')],
        onDelete: (_) async => throw StateError('Network unavailable'),
      ),
    ));

    final item = find.byKey(const ValueKey('notification-item-fails'));
    await tester.drag(item, const Offset(-130, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('notification-delete-button')));
    await tester.pump();

    expect(item, findsOneWidget);
    expect(find.text('Could not delete notification. Please try again.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
