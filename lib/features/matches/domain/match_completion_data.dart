import '../../home/domain/home_match.dart';
import 'match_score_player.dart';

class MatchCompletionData {
  const MatchCompletionData({
    required this.match,
    required this.players,
    required this.scoresSubmitted,
    required this.canSubmitScores,
  });

  final HomeMatch match;
  final List<MatchScorePlayer> players;
  final bool scoresSubmitted;
  final bool canSubmitScores;

  factory MatchCompletionData.fromJson(
    Map<String, dynamic> json, {
    required String currentUserId,
  }) {
    final rawMatch = json['match'];
    final matchJson = rawMatch is Map
        ? rawMatch.map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};

    final rawPlayers = json['players'];
    final players = rawPlayers is List
        ? rawPlayers
              .whereType<Map>()
              .map((item) {
                final player = item.map(
                  (key, value) => MapEntry(key.toString(), value),
                );
                final id = player['id']?.toString() ?? '';
                final rawScore = player['score'];

                return MatchScorePlayer(
                  id: id,
                  displayName: player['name']?.toString() ?? 'Player',
                  avatarUrl: player['avatar_url']?.toString(),
                  isCurrentUser: id == currentUserId,
                  initialScore: rawScore is num
                      ? rawScore.toInt()
                      : int.tryParse(rawScore?.toString() ?? ''),
                );
              })
              .where((player) => player.id.isNotEmpty)
              .toList(growable: false)
        : const <MatchScorePlayer>[];

    return MatchCompletionData(
      match: HomeMatch.fromJson(matchJson),
      players: players,
      scoresSubmitted: json['scores_submitted'] == true,
      canSubmitScores: json['can_submit_scores'] == true,
    );
  }
}
