import '../../../core/network/api_client.dart';
import '../domain/favorite_player.dart';

class PlayerRepository {
  const PlayerRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

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
