class FavoritePlayer {
  const FavoritePlayer({
    required this.id,
    required this.name,
    required this.username,
    required this.gamesCount,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String username;
  final int gamesCount;
  final String? avatarUrl;

  String get secondaryLabel => '@$username · $gamesCount games';
}
