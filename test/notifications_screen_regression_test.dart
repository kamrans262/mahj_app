import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/notifications/data/notifications_preview_data.dart';
import 'package:mahj_app/features/notifications/domain/mahj_notification.dart';
import 'package:mahj_app/features/notifications/presentation/notifications_screen.dart';
import 'package:mahj_app/features/notifications/presentation/widgets/notification_list_item.dart';

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
}

void main() {
  testWidgets('Notifications screen renders builder-driven list safely', (
    tester,
  ) async {
    _setViewport(tester, const Size(430, 900));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(
          notifications: NotificationsPreviewData.create(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('notifications-screen')), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.byType(NotificationListItem), findsWidgets);

    final icon = find
        .byKey(const ValueKey('notification-icon-container'))
        .first;
    expect(tester.getSize(icon), const Size(36, 36));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Notifications screen is overflow-safe on a narrow phone', (
    tester,
  ) async {
    _setViewport(tester, const Size(320, 560));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final notifications = List<MahjNotification>.generate(8, (index) {
      return MahjNotification(
        id: 'narrow-$index',
        type: MahjNotificationType.nearbyMatch,
        title: 'New Match Nearby With A Longer Localized Title',
        message: 'Central City park has a much longer notification description that must wrap naturally without colliding with the time.',
        createdAt: DateTime(2026, 9, 28, 18),
        relatedMatchId: 'preview-nearby-1',
      );
    });

    await tester.pumpWidget(
      MaterialApp(home: NotificationsScreen(notifications: notifications)),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    final lastItem = find.byKey(const ValueKey('notification-item-narrow-7'));
    await tester.scrollUntilVisible(lastItem, 240);
    await tester.pump();
    expect(lastItem, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Opening an unread notification marks it read and emits action', (
    tester,
  ) async {
    _setViewport(tester, const Size(430, 900));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    MahjNotification? opened;
    List<MahjNotification>? updated;
    final notification = MahjNotification(
      id: 'tap-test',
      type: MahjNotificationType.nearbyMatch,
      title: 'New Match Nearby',
      message: 'Central City park (12miles) Check it out',
      createdAt: DateTime(2026, 9, 28, 18),
      relatedMatchId: 'preview-nearby-1',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(
          notifications: [notification],
          onReadStateChanged: (value) => updated = value,
          onNotificationTap: (value) async => opened = value,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('notification-item-tap-test')));
    await tester.pump();

    expect(opened?.id, 'tap-test');
    expect(opened?.isRead, isTrue);
    expect(updated?.single.isRead, isTrue);
    expect(tester.takeException(), isNull);
  });
}
