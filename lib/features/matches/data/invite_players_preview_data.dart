import '../../../app/app_assets.dart';
import '../../home/domain/home_match.dart';
import '../domain/invite_player_result.dart';

abstract final class InvitePlayersPreviewData {
  static List<InvitePlayerResult> forMatch(HomeMatch match) {
    return List<InvitePlayerResult>.generate(3, (index) {
      return InvitePlayerResult(
        id: 'demo-invite-${index + 1}',
        searchText: switch (index) {
          0 => 'Alex Morgan',
          1 => 'Jordan Lee',
          _ => 'Taylor Smith',
        },
        title: match.location,
        startsAt: match.startsAt,
        currentPlayers: match.currentPlayers,
        maxPlayers: match.maxPlayers,
        sportImageAsset: AppAssets.sportImage,
      );
    }, growable: false);
  }
}
