import '../../../core/network/api_client.dart';
import '../domain/favorite_player.dart';
import '../../home/domain/home_match.dart';
import '../domain/player_profile_data.dart';
import '../domain/mutual_games_page.dart';

class PlayerRepository {
  const PlayerRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<PlayerProfileData> fetchProfile(
    String playerId, {
    String avatarAsset = '',
    bool canInvite = true,
    bool canReport = true,
    bool canBlock = true,
  }) async {
    final payload = await _apiClient.get('/users/$playerId/profile?per_page=2');
    final raw = payload['player'];
    if (raw is! Map) {
      throw const FormatException('Player profile is unavailable.');
    }
    final json = _normalize(raw);
    final games = _parseGames(payload['mutual_games']);

    return PlayerProfileData(
      id: json['id']?.toString() ?? playerId,
      name: json['name']?.toString() ?? 'Player',
      email: '',
      address: '',
      postCode: '',
      avatarAsset: avatarAsset,
      avatarUrl: json['avatar_url']?.toString(),
      matchesPlayed: _asInt(json['matches_played']),
      matchesHosted: _asInt(json['matches_hosted']),
      attendancePercent: _asInt(json['attendance_percent']),
      memberSinceLabel: json['member_since_year']?.toString() ?? '—',
      mutualGames: games,
      mutualGamesTotal: _asInt(json['mutual_games_total']),
      canInvite: canInvite,
      canReport: canReport,
      canBlock: canBlock,
    );
  }

  Future<MutualGamesPage> fetchMutualGames(
    String playerId, {
    int page = 1,
  }) async {
    final payload = await _apiClient.get(
      '/users/$playerId/profile?per_page=20&page=$page',
    );
    final meta = payload['meta'];
    final metadata = meta is Map ? _normalize(meta) : const <String, dynamic>{};
    return MutualGamesPage(
      games: _parseGames(payload['mutual_games']),
      hasMore: metadata['has_more'] == true,
    );
  }

  List<HomeMatch> _parseGames(dynamic raw) {
    if (raw is! List) return const <HomeMatch>[];
    return raw.whereType<Map>().map((item) =>
        HomeMatch.fromJson(_normalize(item))).toList(growable: false);
  }

  Future<List<FavoritePlayer>> listFavorites() async {
    final payload = await _apiClient.get('/favorite-players');
    final raw = payload['data'];
    if (raw is! List) return const <FavoritePlayer>[];

    return raw
        .whereType<Map>()
        .map((item) => _fromJson(_normalize(item)))
        .whereType<FavoritePlayer>()
        .toList(growable: false);
  }

  Future<bool> isFavorite(String playerId) async {
    final payload = await _apiClient.get('/users/$playerId/favorite');
    return payload['is_favorite'] == true;
  }

  Future<bool> setFavorite(String playerId, bool favorite) async {
    final payload = favorite
        ? await _apiClient.post('/users/$playerId/favorite')
        : await _apiClient.delete('/users/$playerId/favorite');

    return payload['is_favorite'] == true;
  }

  FavoritePlayer? _fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    if (id.isEmpty) return null;

    return FavoritePlayer(
      id: id,
      name: json['name']?.toString() ?? 'Player',
      username: json['username']?.toString() ?? 'player',
      gamesCount: _asInt(json['games_count']),
      avatarUrl: json['avatar_url']?.toString(),
    );
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic> _normalize(Map value) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
}
