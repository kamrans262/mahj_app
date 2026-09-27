import 'home_match.dart';

class HomeData {
  const HomeData({
    required this.greeting,
    required this.displayName,
    required this.subtitle,
    required this.location,
    required this.unreadNotificationCount,
    required this.unreadMessageCount,
    required this.upcomingMatches,
    required this.nearbyMatches,
  });

  final String greeting;
  final String displayName;
  final String subtitle;
  final String location;
  final int unreadNotificationCount;
  final int unreadMessageCount;
  final List<HomeMatch> upcomingMatches;
  final List<HomeMatch> nearbyMatches;
}
