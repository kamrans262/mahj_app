import '../../home/domain/home_match.dart';
import 'player_profile_data.dart';

class PlayerProfileRouteArgs {
  const PlayerProfileRouteArgs({required this.player, this.inviteMatch});

  final PlayerProfileData player;
  final HomeMatch? inviteMatch;
}
