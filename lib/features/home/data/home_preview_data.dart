import '../../../app/app_assets.dart';
import '../domain/home_data.dart';
import '../domain/home_match.dart';

abstract final class HomePreviewData {
  static HomeData create() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 18);

    return HomeData(
      greeting: now.hour < 12 ? 'Morning' : 'Afternoon',
      displayName: 'John',
      subtitle: 'Find and join matches near you',
      location: '1001, New York, NY',
      unreadNotificationCount: 3,
      unreadMessageCount: 3,
      upcomingMatches: [
        HomeMatch(
          id: 'preview-upcoming-1',
          sportName: 'Mah Jongg',
          location: 'Central park, NY',
          startsAt: tomorrow,
          currentPlayers: 3,
          maxPlayers: 4,
          status: MatchStatus.open,
          bannerAsset: AppAssets.homeBannerImage,
        ),
        HomeMatch(
          id: 'preview-upcoming-2',
          sportName: 'Mah Jongg',
          location: 'Central Park Courts',
          startsAt: tomorrow.add(const Duration(hours: 2)),
          currentPlayers: 2,
          maxPlayers: 4,
          status: MatchStatus.confirmed,
          sportIconAsset: AppAssets.genericSportIcon,
          bannerAsset: AppAssets.sportImage,
        ),
      ],
      nearbyMatches: [
        HomeMatch(
          id: 'preview-nearby-1',
          sportName: 'Mah Jongg',
          location: 'Central Park Courts',
          startsAt: tomorrow,
          currentPlayers: 2,
          maxPlayers: 4,
          status: MatchStatus.open,
          sportIconAsset: AppAssets.genericSportIcon,
        ),
        HomeMatch(
          id: 'preview-nearby-2',
          sportName: 'Mah Jongg',
          location: 'Central Park Courts',
          startsAt: tomorrow,
          currentPlayers: 2,
          maxPlayers: 4,
          status: MatchStatus.confirmed,
          sportIconAsset: AppAssets.genericSportIcon,
        ),
        HomeMatch(
          id: 'preview-nearby-3',
          sportName: 'Mah Jongg',
          location: 'Central Park Courts',
          startsAt: tomorrow,
          currentPlayers: 2,
          maxPlayers: 4,
          status: MatchStatus.cancelled,
          sportIconAsset: AppAssets.genericSportIcon,
        ),
      ],
    );
  }
}
