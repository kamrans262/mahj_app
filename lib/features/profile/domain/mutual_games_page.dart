import '../../home/domain/home_match.dart';

class MutualGamesPage {
  const MutualGamesPage({required this.games, required this.hasMore});

  final List<HomeMatch> games;
  final bool hasMore;
}
