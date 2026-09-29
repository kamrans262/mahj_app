import '../../home/data/home_preview_data.dart';
import '../../home/domain/home_match.dart';
import '../domain/mahj_notification.dart';

abstract final class NotificationsPreviewData {
  static List<MahjNotification> create() {
    final now = DateTime.now();
    final sixPm = DateTime(now.year, now.month, now.day, 18);
    final home = HomePreviewData.create();
    final matches = <HomeMatch>[...home.nearbyMatches, ...home.upcomingMatches];

    if (matches.isEmpty) return const <MahjNotification>[];

    return List<MahjNotification>.generate(7, (index) {
      final match = matches[index % matches.length];
      return MahjNotification(
        id: 'demo-notification-${index + 1}',
        type: MahjNotificationType.nearbyMatch,
        title: 'New Match Nearby',
        message: '${match.location} Check it out',
        createdAt: sixPm,
        isRead: index >= 3,
        relatedMatchId: match.id,
      );
    });
  }
}
