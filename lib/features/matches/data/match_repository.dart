import '../../../app/app_assets.dart';
import '../../../core/network/api_client.dart';
import '../../home/domain/home_match.dart';
import '../../home/domain/match_filters.dart';
import '../domain/create_match_form_state.dart';
import '../domain/invite_player_result.dart';
import '../domain/my_matches_data.dart';
import '../domain/sport_option.dart';

class MatchRepository {
  const MatchRepository({required ApiClient apiClient}) : this._(apiClient);

  const MatchRepository._(this._apiClient);

  final ApiClient _apiClient;

  Future<List<SportOption>> listSports() async {
    final payload = await _apiClient.get('/sports');
    final raw = payload['data'];
    if (raw is! List) return const <SportOption>[];

    return raw
        .whereType<Map>()
        .map(
          (item) => SportOption.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .where((sport) => sport.name.isNotEmpty && sport.slug.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<HomeMatch>> list({
    MatchFilters? filters,
    String query = '',
    bool discoverOnly = false,
  }) async {
    final params = <String, String>{};

    if (filters != null) {
      params['radius_miles'] = filters.radiusMiles.toStringAsFixed(0);
      params['date_filter'] = filters.dateFilter.apiValue;
      params['open_spots_only'] = filters.showOpenOnly ? '1' : '0';
      params['sort'] = filters.sortOption.apiValue;
      params['timezone_offset_minutes'] = DateTime.now()
          .timeZoneOffset
          .inMinutes
          .toString();

      if (filters.hasCoordinates) {
        params['latitude'] = filters.latitude!.toStringAsFixed(7);
        params['longitude'] = filters.longitude!.toStringAsFixed(7);
      }
    }

    if (query.trim().isNotEmpty) {
      params['q'] = query.trim();
    }
    if (discoverOnly) {
      params['discover_only'] = '1';
    }

    final path = params.isEmpty
        ? '/matches'
        : Uri(path: '/matches', queryParameters: params).toString();
    final payload = await _apiClient.get(path);
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

  Future<MyMatchesData> listMyMatches() async {
    final payload = await _apiClient.get('/my-matches');

    List<MyMatchesItem> mapMatches(dynamic raw) {
      if (raw is! List) return const <MyMatchesItem>[];

      return raw
          .whereType<Map>()
          .map((item) {
            final json = item.map(
              (key, value) => MapEntry(key.toString(), value),
            );
            return MyMatchesItem(
              match: HomeMatch.fromJson(json),
              sportImageAsset: AppAssets.sportImage,
            );
          })
          .toList(growable: false);
    }

    final inviteRaw = payload['invites'];
    final invites = inviteRaw is List
        ? inviteRaw.whereType<Map>().map((item) {
            final json = item.map(
              (key, value) => MapEntry(key.toString(), value),
            );
            final matchRaw = json['match'];
            final matchJson = matchRaw is Map
                ? matchRaw.map(
                    (key, value) => MapEntry(key.toString(), value),
                  )
                : const <String, dynamic>{};
            final inviterRaw = json['inviter'];
            final inviter = inviterRaw is Map
                ? inviterRaw.map(
                    (key, value) => MapEntry(key.toString(), value),
                  )
                : const <String, dynamic>{};

            return MyMatchesItem(
              match: HomeMatch.fromJson(matchJson),
              sportImageAsset: AppAssets.sportImage,
              invitationId: json['id']?.toString(),
              inviterName: inviter['name']?.toString(),
            );
          }).toList(growable: false)
        : const <MyMatchesItem>[];

    return MyMatchesData(
      unreadNotificationCount: 0,
      unreadMessageCount: 0,
      upcoming: mapMatches(payload['upcoming']),
      createdByMe: mapMatches(payload['created_by_me']),
      invites: invites,
    );
  }

  Future<List<InvitePlayerResult>> searchInviteCandidates(
    HomeMatch match,
    String query,
  ) async {
    final trimmed = query.trim();
    final path = trimmed.isEmpty
        ? '/matches/${match.id}/invite-candidates'
        : Uri(
            path: '/matches/${match.id}/invite-candidates',
            queryParameters: {'q': trimmed},
          ).toString();
    final payload = await _apiClient.get(path);
    final raw = payload['data'];
    if (raw is! List) return const <InvitePlayerResult>[];

    return raw.whereType<Map>().map((item) {
      final json = item.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final name = json['name']?.toString().trim() ?? '';
      final email = json['email']?.toString().trim() ?? '';
      final city = json['city']?.toString().trim() ?? '';

      return InvitePlayerResult(
        id: json['id']?.toString() ?? '',
        searchText: [name, email, city].where((value) => value.isNotEmpty).join(' '),
        title: name.isEmpty ? email : name,
        startsAt: match.startsAt,
        currentPlayers: match.currentPlayers,
        maxPlayers: match.maxPlayers,
        sportImageAsset: AppAssets.sportImage,
      );
    }).where((result) => result.id.isNotEmpty).toList(growable: false);
  }

  Future<void> sendInvitations(
    String matchId,
    Set<String> userIds,
  ) async {
    await _apiClient.post(
      '/matches/$matchId/invitations',
      body: {
        'user_ids': userIds
            .map(int.tryParse)
            .whereType<int>()
            .toList(growable: false),
      },
    );
  }

  Future<HomeMatch> acceptInvitation(String invitationId) async {
    final payload = await _apiClient.post(
      '/invitations/$invitationId/accept',
    );
    return _matchFromEnvelope(payload);
  }

  Future<void> declineInvitation(String invitationId) async {
    await _apiClient.post('/invitations/$invitationId/decline');
  }

  Future<HomeMatch> fetch(String matchId) async {
    final payload = await _apiClient.get('/matches/$matchId');
    return _matchFromEnvelope(payload);
  }

  Future<HomeMatch> create(CreateMatchRequest request) async {
    final payload = await _apiClient.post(
      '/matches',
      body: {
        'sport_id': request.sportId,
        'custom_sport_name': request.customSportName,
        'name': request.sportName,
        'location_address': request.locationAddress,
        'venue_name': request.venueName,
        'notes': request.notes,
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
