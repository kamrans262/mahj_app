import '../../../app/app_assets.dart';
import '../domain/home_match.dart';

abstract final class NearbyMatchesPreviewData {
  static List<HomeMatch> create() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 18);

    final statuses = <MatchStatus>[
      MatchStatus.open,
      MatchStatus.confirmed,
      MatchStatus.cancelled,
      MatchStatus.full,
    ];

    return List<HomeMatch>.generate(12, (index) {
      final status = statuses[index % statuses.length];
      final maxPlayers = 4;
      final currentPlayers = status == MatchStatus.full ? 4 : 2;

      return HomeMatch(
        id: 'nearby-preview-${index + 1}',
        sportName: 'Football',
        location: 'Central Park Courts',
        startsAt: tomorrow.add(Duration(minutes: index * 30)),
        currentPlayers: currentPlayers,
        maxPlayers: maxPlayers,
        status: status,
        sportIconAsset: AppAssets.homeFootballIcon,
        isJoinable: status == MatchStatus.open,
      );
    });
  }
}
