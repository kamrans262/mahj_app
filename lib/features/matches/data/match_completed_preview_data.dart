import '../../../app/app_assets.dart';
import '../domain/match_score_player.dart';

abstract final class MatchCompletedPreviewData {
  static const String inviterName = 'Austen Parker';
  static const String inviterAvatarAsset = AppAssets.demoAvatarOne;

  static const List<MatchScorePlayer> players = [
    MatchScorePlayer(
      id: 'player-austen',
      displayName: 'Austen Parker',
      avatarAsset: AppAssets.demoAvatarOne,
    ),
    MatchScorePlayer(
      id: 'current-user',
      displayName: 'You',
      avatarAsset: AppAssets.demoAvatarTwo,
      isCurrentUser: true,
    ),
    MatchScorePlayer(
      id: 'player-alex',
      displayName: 'Alex Turner',
      avatarAsset: AppAssets.demoAvatarThree,
    ),
    MatchScorePlayer(
      id: 'player-robert',
      displayName: 'Robert',
      avatarAsset: AppAssets.demoAvatarOne,
    ),
  ];
}
