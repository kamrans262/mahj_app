class MatchScorePlayer {
  const MatchScorePlayer({
    required this.id,
    required this.displayName,
    required this.avatarAsset,
    this.isCurrentUser = false,
    this.initialScore,
  });

  final String id;
  final String displayName;
  final String avatarAsset;
  final bool isCurrentUser;
  final int? initialScore;
}
