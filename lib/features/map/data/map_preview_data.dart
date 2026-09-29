import '../../../app/app_assets.dart';
import '../../home/domain/home_match.dart';
import '../domain/map_match_marker.dart';

abstract final class MapPreviewData {
  static List<MapMatchMarker> create() {
    final now = DateTime.now();
    final todayAtSix = DateTime(now.year, now.month, now.day, 18);
    final tomorrowAtSix = DateTime(now.year, now.month, now.day + 1, 18);

    const avatars = <String>[
      AppAssets.demoAvatarOne,
      AppAssets.demoAvatarTwo,
      AppAssets.demoAvatarThree,
    ];

    return [
      MapMatchMarker(
        match: HomeMatch(
          id: 'map-preview-basketball-1',
          sportName: 'Basket Ball',
          location: 'Central Park Courts',
          startsAt: todayAtSix,
          currentPlayers: 2,
          maxPlayers: 4,
          status: MatchStatus.open,
          sportIconAsset: AppAssets.basketballIcon,
        ),
        normalizedX: 0.30,
        normalizedY: 0.64,
        distanceMiles: 4.5,
        playerAvatarAssets: avatars,
      ),
      MapMatchMarker(
        match: HomeMatch(
          id: 'map-preview-football-1',
          sportName: 'Football',
          location: 'Riverside Field',
          startsAt: todayAtSix.add(const Duration(minutes: 30)),
          currentPlayers: 3,
          maxPlayers: 6,
          status: MatchStatus.open,
          sportIconAsset: AppAssets.homeFootballIcon,
        ),
        normalizedX: 0.38,
        normalizedY: 0.23,
        distanceMiles: 7.1,
        playerAvatarAssets: avatars,
      ),
      MapMatchMarker(
        match: HomeMatch(
          id: 'map-preview-basketball-2',
          sportName: 'Basket Ball',
          location: 'East Court',
          startsAt: tomorrowAtSix.add(const Duration(hours: 1)),
          currentPlayers: 2,
          maxPlayers: 4,
          status: MatchStatus.confirmed,
          sportIconAsset: AppAssets.basketballIcon,
        ),
        normalizedX: 0.76,
        normalizedY: 0.62,
        distanceMiles: 9.2,
        playerAvatarAssets: avatars,
      ),
      MapMatchMarker(
        match: HomeMatch(
          id: 'map-preview-football-2',
          sportName: 'Football',
          location: 'Westside Ground',
          startsAt: tomorrowAtSix.subtract(const Duration(minutes: 30)),
          currentPlayers: 4,
          maxPlayers: 6,
          status: MatchStatus.open,
          sportIconAsset: AppAssets.homeFootballIcon,
        ),
        normalizedX: 0.62,
        normalizedY: 0.32,
        distanceMiles: 3.8,
        playerAvatarAssets: avatars,
      ),
    ];
  }
}
