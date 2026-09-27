enum MatchStatus { open, confirmed, cancelled }

class HomeMatch {
  const HomeMatch({
    required this.id,
    required this.sportName,
    required this.location,
    required this.startsAt,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.status,
    this.sportIconAsset = '',
    this.bannerAsset = '',
    this.isJoinable = true,
  });

  final String id;
  final String sportName;
  final String location;
  final DateTime startsAt;
  final int currentPlayers;
  final int maxPlayers;
  final MatchStatus status;
  final String sportIconAsset;
  final String bannerAsset;
  final bool isJoinable;

  bool get isFull => currentPlayers >= maxPlayers;
}
