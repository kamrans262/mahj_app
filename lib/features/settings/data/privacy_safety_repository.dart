import '../../../app/app_assets.dart';
import '../../../core/network/api_client.dart';
import '../domain/privacy_safety_data.dart';

class PrivacySafetyRepository {
  const PrivacySafetyRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<PrivacySafetyData> load() async {
    final payload = await _apiClient.get('/safety');

    final blockedUsers = _parseUsers(payload['blocked_users']);
    final reportsRaw = payload['report_history'];
    final reportHistory = reportsRaw is List
        ? reportsRaw
              .whereType<Map>()
              .map((item) => _reportFromJson(_normalize(item)))
              .whereType<PrivacyReportHistoryEntry>()
              .toList(growable: false)
        : const <PrivacyReportHistoryEntry>[];

    return PrivacySafetyData(
      blockedUsers: blockedUsers,
      reportHistory: reportHistory,
    );
  }

  Future<List<PrivacySafetyUser>> searchUsers(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const <PrivacySafetyUser>[];

    final path = Uri(
      path: '/users/search',
      queryParameters: {'q': trimmed},
    ).toString();
    final payload = await _apiClient.get(path);
    return _parseUsers(payload['data']);
  }

  Future<void> reportPlayer({
    required String playerId,
    required String reasonId,
    String notes = '',
  }) async {
    await _apiClient.post(
      '/users/$playerId/report',
      body: {
        'reason_id': reasonId,
        'notes': notes.trim().isEmpty ? null : notes.trim(),
      },
    );
  }

  Future<void> blockPlayer({
    required String playerId,
    required String reasonId,
  }) async {
    await _apiClient.post(
      '/users/$playerId/block',
      body: {'reason_id': reasonId},
    );
  }

  Future<void> unblockPlayer(String playerId) async {
    await _apiClient.delete('/users/$playerId/block');
  }

  List<PrivacySafetyUser> _parseUsers(dynamic raw) {
    if (raw is! List) return const <PrivacySafetyUser>[];

    return raw
        .whereType<Map>()
        .map((item) => _userFromJson(_normalize(item)))
        .whereType<PrivacySafetyUser>()
        .toList(growable: false);
  }

  PrivacyReportHistoryEntry? _reportFromJson(Map<String, dynamic> json) {
    final userRaw = json['reported_user'];
    if (userRaw is! Map) return null;

    final player = _userFromJson(_normalize(userRaw));
    if (player == null) return null;

    return PrivacyReportHistoryEntry(
      id: json['id']?.toString() ?? '',
      player: player,
      status: json['status']?.toString() == 'closed'
          ? PrivacyReportStatus.closed
          : PrivacyReportStatus.pending,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      reason: json['reason']?.toString(),
    );
  }

  PrivacySafetyUser? _userFromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    if (id.isEmpty) return null;

    return PrivacySafetyUser(
      id: id,
      displayName: json['name']?.toString() ?? 'Player',
      username: json['username']?.toString() ?? 'player',
      gamesCount: _asInt(json['games_count']),
      avatarAsset: AppAssets.bottomProfileIcon,
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
