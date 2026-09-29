import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/home/data/home_preview_data.dart';
import 'package:mahj_app/features/notifications/data/notifications_preview_data.dart';

void main() {
  test('Preview notifications reference real current preview matches', () {
    final home = HomePreviewData.create();
    final validIds = <String>{
      ...home.nearbyMatches.map((match) => match.id),
      ...home.upcomingMatches.map((match) => match.id),
    };
    final notifications = NotificationsPreviewData.create();

    expect(notifications, isNotEmpty);
    for (final notification in notifications) {
      expect(notification.relatedMatchId, isNotNull);
      expect(validIds, contains(notification.relatedMatchId));
    }
  });
}
