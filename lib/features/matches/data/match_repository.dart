import '../../../core/network/api_client.dart';
import '../../home/domain/home_match.dart';
import '../domain/create_match_form_state.dart';

class MatchRepository {
  const MatchRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<HomeMatch>> list() async {
    final payload = await _apiClient.get('/matches');
    final raw = payload['data'];
    if (raw is! List) return const <HomeMatch>[];

    return raw
        .whereType<Map>()
        .map(
          (item) => HomeMatch.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(growable: false);
  }

  Future<HomeMatch> fetch(String matchId) async {
    final payload = await _apiClient.get('/matches/$matchId');
    return _matchFromEnvelope(payload);
  }

  Future<HomeMatch> create(CreateMatchRequest request) async {
    final payload = await _apiClient.post(
      '/matches',
      body: {
        'location_address': request.locationAddress,
        'venue_name': request.venueName,
        'starts_at': request.startsAt.toUtc().toIso8601String(),
        'is_public': request.isPublicMatch,
        'is_invite_only': request.isInviteOnly,
        'latitude': request.latitude,
        'longitude': request.longitude,
      },
    );

    return _matchFromEnvelope(payload);
  }

  Future<HomeMatch> join(String matchId) async {
    final payload = await _apiClient.post('/matches/$matchId/join');
    return _matchFromEnvelope(payload);
  }

  Future<HomeMatch> leave(String matchId) async {
    final payload = await _apiClient.post('/matches/$matchId/leave');
    return _matchFromEnvelope(payload);
  }

  Future<HomeMatch> cancel(String matchId) async {
    final payload = await _apiClient.post('/matches/$matchId/cancel');
    return _matchFromEnvelope(payload);
  }

  HomeMatch _matchFromEnvelope(Map<String, dynamic> payload) {
    final raw = payload['match'];
    if (raw is Map<String, dynamic>) {
      return HomeMatch.fromJson(raw);
    }
    if (raw is Map) {
      return HomeMatch.fromJson(
        raw.map((key, value) => MapEntry(key.toString(), value)),
      );
    }

    throw const FormatException('Match response is missing match data.');
  }
}
