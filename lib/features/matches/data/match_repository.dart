import 'dart:math' as math;

import '../../../app/app_assets.dart';
import '../../../core/network/api_client.dart';
import '../../home/domain/home_match.dart';
import '../../home/domain/match_filters.dart';
import '../domain/create_match_form_state.dart';
import '../domain/invite_player_result.dart';
import '../domain/match_completion_data.dart';
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

  Future<MyMatchesData> listMyMatches({
    double? latitude,
    double? longitude,
    int upcomingPage = 1,
    int createdByMePage = 1,
    int invitesPage = 1,
    int completedPage = 1,
    int cancelledPage = 1,
    int perPage = 20,
  }) async {
    final params = <String, String>{
      'upcoming_page': upcomingPage.toString(),
      'created_page': createdByMePage.toString(),
      'invites_page': invitesPage.toString(),
      'completed_page': completedPage.toString(),
      'cancelled_page': cancelledPage.toString(),
      'per_page': perPage.toString(),
    };

    if (latitude != null && longitude != null) {
      params['latitude'] = latitude.toStringAsFixed(7);
      params['longitude'] = longitude.toStringAsFixed(7);
    }

    final path = Uri(path: '/my-matches', queryParameters: params).toString();
    final payload = await _apiClient.get(path);

    HomeMatch withFallbackDistance(HomeMatch match) {
      if (match.distanceMiles != null ||
          latitude == null ||
          longitude == null ||
          match.latitude == null ||
          match.longitude == null) {
        return match;
      }

      final distance = _distanceMiles(
        latitude,
        longitude,
        match.latitude!,
        match.longitude!,
      );
      return match.copyWith(distanceMiles: distance);
    }

    List<MyMatchesItem> mapMatches(dynamic raw) {
      if (raw is! List) return const <MyMatchesItem>[];

      final seenMatchIds = <String>{};

      return raw
          .whereType<Map>()
          .map((item) {
            final json = item.map(
              (key, value) => MapEntry(key.toString(), value),
            );
            return MyMatchesItem(
              match: withFallbackDistance(HomeMatch.fromJson(json)),
              sportImageAsset: AppAssets.sportImage,
            );
          })
          .where((item) => seenMatchIds.add(item.match.id))
          .toList(growable: false);
    }

    final upcoming = mapMatches(payload['upcoming']);
    final createdByMe = mapMatches(payload['created_by_me']);
    final completed = mapMatches(payload['completed']);
    final cancelled = mapMatches(payload['cancelled']);
    final alreadyOwnedOrJoinedIds = <String>{
      ...upcoming.map((item) => item.match.id),
      ...createdByMe.map((item) => item.match.id),
    };

    final inviteRaw = payload['invites'];
    final seenInviteMatchIds = <String>{};
    final invites = inviteRaw is List
        ? inviteRaw
              .whereType<Map>()
              .map((item) {
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
                  match: withFallbackDistance(HomeMatch.fromJson(matchJson)),
                  sportImageAsset: AppAssets.sportImage,
                  invitationId: json['id']?.toString(),
                  inviterName: inviter['name']?.toString(),
                  inviterAvatarUrl: inviter['avatar_url']?.toString(),
                );
              })
              .where(
                (item) =>
                    !alreadyOwnedOrJoinedIds.contains(item.match.id) &&
                    seenInviteMatchIds.add(item.match.id),
              )
              .toList(growable: false)
        : const <MyMatchesItem>[];

    Map<String, dynamic> readMeta(String key) {
      final rawMeta = payload['meta'];
      if (rawMeta is! Map) return const <String, dynamic>{};
      final normalized = rawMeta.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final value = normalized[key];
      if (value is! Map) return const <String, dynamic>{};
      return value.map((key, value) => MapEntry(key.toString(), value));
    }

    int readPage(Map<String, dynamic> meta, int fallback) {
      final value = meta['page'];
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    bool readHasMore(Map<String, dynamic> meta) => meta['has_more'] == true;

    final upcomingMeta = readMeta('upcoming');
    final createdMeta = readMeta('created_by_me');
    final invitesMeta = readMeta('invites');
    final completedMeta = readMeta('completed');
    final cancelledMeta = readMeta('cancelled');

    return MyMatchesData(
      unreadNotificationCount: 0,
      unreadMessageCount: 0,
      upcoming: upcoming,
      createdByMe: createdByMe,
      invites: invites,
      completed: completed,
      cancelled: cancelled,
      upcomingPage: readPage(upcomingMeta, upcomingPage),
      createdByMePage: readPage(createdMeta, createdByMePage),
      invitesPage: readPage(invitesMeta, invitesPage),
      completedPage: readPage(completedMeta, completedPage),
      cancelledPage: readPage(cancelledMeta, cancelledPage),
      hasMoreUpcoming: readHasMore(upcomingMeta),
      hasMoreCreatedByMe: readHasMore(createdMeta),
      hasMoreInvites: readHasMore(invitesMeta),
      hasMoreCompleted: readHasMore(completedMeta),
      hasMoreCancelled: readHasMore(cancelledMeta),
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

    return raw
        .whereType<Map>()
        .map((item) {
          final json = item.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          final name = json['name']?.toString().trim() ?? '';
          final email = json['email']?.toString().trim() ?? '';
          final city = json['city']?.toString().trim() ?? '';

          return InvitePlayerResult(
            id: json['id']?.toString() ?? '',
            searchText: [
              name,
              email,
              city,
            ].where((value) => value.isNotEmpty).join(' '),
            title: name.isEmpty ? email : name,
            startsAt: match.startsAt,
            currentPlayers: match.currentPlayers,
            maxPlayers: match.maxPlayers,
            sportImageAsset: AppAssets.sportImage,
            avatarUrl: json['avatar_url']?.toString(),
            latitude: match.latitude,
            longitude: match.longitude,
          );
        })
        .where((result) => result.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> sendInvitations(String matchId, Set<String> userIds) async {
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
    final payload = await _apiClient.post('/invitations/$invitationId/accept');
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

  Future<HomeMatch> complete(String matchId) async {
    final payload = await _apiClient.post('/matches/$matchId/complete');
    return _matchFromEnvelope(payload);
  }

  Future<MatchCompletionData> fetchCompletion(
    String matchId, {
    required String currentUserId,
  }) async {
    final payload = await _apiClient.get('/matches/$matchId/completion');
    return MatchCompletionData.fromJson(
      payload,
      currentUserId: currentUserId,
    );
  }

  Future<MatchCompletionData> submitScores(
    String matchId,
    Map<String, int> scores, {
    required String currentUserId,
  }) async {
    final payload = await _apiClient.post(
      '/matches/$matchId/scores',
      body: {
        'scores': scores.entries
            .map(
              (entry) => {
                'player_id': int.tryParse(entry.key) ?? entry.key,
                'score': entry.value,
              },
            )
            .toList(growable: false),
      },
    );

    return MatchCompletionData.fromJson(
      payload,
      currentUserId: currentUserId,
    );
  }

  double _distanceMiles(
    double originLatitude,
    double originLongitude,
    double targetLatitude,
    double targetLongitude,
  ) {
    const earthRadiusMiles = 3958.7613;

    final latitudeDelta = _degreesToRadians(targetLatitude - originLatitude);
    final longitudeDelta = _degreesToRadians(targetLongitude - originLongitude);
    final originLatitudeRadians = _degreesToRadians(originLatitude);
    final targetLatitudeRadians = _degreesToRadians(targetLatitude);

    final a =
        math.pow(math.sin(latitudeDelta / 2), 2).toDouble() +
        math.cos(originLatitudeRadians) *
            math.cos(targetLatitudeRadians) *
            math.pow(math.sin(longitudeDelta / 2), 2).toDouble();

    final centralAngle = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMiles * centralAngle;
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;

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
