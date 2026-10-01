import '../../../app/app_assets.dart';

class MatchScorePlayer {
  const MatchScorePlayer({
    required this.id,
    required this.displayName,
    this.avatarAsset = AppAssets.bottomProfileIcon,
    this.avatarUrl,
    this.isCurrentUser = false,
    this.initialScore,
  });

  final String id;
  final String displayName;
  final String avatarAsset;
  final String? avatarUrl;
  final bool isCurrentUser;
  final int? initialScore;
}
