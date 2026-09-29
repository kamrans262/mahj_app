import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/notifications/domain/mahj_notification.dart';
import 'package:mahj_app/features/notifications/presentation/notifications_screen.dart';

void main() {
  testWidgets(
    'Notification rows have 20px vertical content padding and larger text gap',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final notification = MahjNotification(
        id: 'spacing-test',
        type: MahjNotificationType.nearbyMatch,
        title: 'New Match Nearby',
        message: 'A longer nearby match notification that wraps safely on a narrow phone.',
        createdAt: DateTime(2026, 9, 28, 18),
        isRead: false,
        relatedMatchId: 'my-upcoming-1',
      );

      await tester.pumpWidget(
        MaterialApp(home: NotificationsScreen(notifications: [notification])),
      );
      await tester.pump();

      final padding = tester.widget<Padding>(
        find.byKey(const ValueKey('notification-content-padding')),
      );
      expect(padding.padding, const EdgeInsets.symmetric(vertical: 20));

      final titleRect = tester.getRect(
        find.byKey(const ValueKey('notification-title')),
      );
      final messageRect = tester.getRect(
        find.byKey(const ValueKey('notification-message')),
      );
      expect(messageRect.top - titleRect.bottom, greaterThanOrEqualTo(9.5));
      expect(tester.takeException(), isNull);
    },
  );
}
