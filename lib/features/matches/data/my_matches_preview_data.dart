import '../../../app/app_assets.dart';
import '../../home/domain/home_match.dart';
import '../domain/my_matches_data.dart';

abstract final class MyMatchesPreviewData {
  static MyMatchesData create() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 18);

    MyMatchesItem item({
      required String id,
      required MatchStatus status,
      int currentPlayers = 4,
      int maxPlayers = 6,
      bool mapPreview = false,
      int hourOffset = 0,
    }) {
      return MyMatchesItem(
        match: HomeMatch(
          id: id,
          sportName: 'Football',
          location: 'Central Park View',
          startsAt: tomorrow.add(Duration(hours: hourOffset)),
          currentPlayers: currentPlayers,
          maxPlayers: maxPlayers,
          status: status,
          sportIconAsset: AppAssets.homeFootballIcon,
          bannerAsset: AppAssets.sportImage,
          isJoinable: status == MatchStatus.open,
        ),
        sportImageAsset: AppAssets.sportImage,
        markerNormalizedX: mapPreview ? 0.52 : null,
        markerNormalizedY: mapPreview ? 0.54 : null,
      );
    }

    return MyMatchesData(
      unreadNotificationCount: 3,
      unreadMessageCount: 3,
      upcoming: [
        item(id: 'my-upcoming-1', status: MatchStatus.open),
        item(id: 'my-upcoming-2', status: MatchStatus.confirmed),
        item(id: 'my-upcoming-3', status: MatchStatus.full, currentPlayers: 6),
        item(id: 'my-upcoming-4', status: MatchStatus.open),
      ],
      createdByMe: [
        item(id: 'my-created-1', status: MatchStatus.open, mapPreview: true),
        item(id: 'my-created-2', status: MatchStatus.confirmed),
      ],
      invites: [
        item(id: 'my-invite-1', status: MatchStatus.open),
        item(id: 'my-invite-2', status: MatchStatus.full, currentPlayers: 6),
      ],
      completed: [
        item(id: 'my-completed-1', status: MatchStatus.completed),
      ],
      cancelled: [
        item(id: 'my-cancelled-1', status: MatchStatus.cancelled),
      ],
    );
  }
}
