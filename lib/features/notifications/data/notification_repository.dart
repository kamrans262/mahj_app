import '../../../core/network/api_client.dart';
import '../domain/mahj_notification.dart';
import '../domain/notification_preferences.dart';

class NotificationPage {
  const NotificationPage({
    required this.notifications,
    required this.page,
    required this.hasMore,
    required this.unreadCount,
  });

  final List<MahjNotification> notifications;
  final int page;
  final bool hasMore;
  final int unreadCount;
}

class NotificationReadResult {
  const NotificationReadResult({
    required this.notification,
    required this.unreadCount,
  });

  final MahjNotification notification;
  final int unreadCount;
}

class NotificationRepository {
  const NotificationRepository({required ApiClient apiClient})
    : this._(apiClient);

  const NotificationRepository._(this._apiClient);

  final ApiClient _apiClient;

  Future<NotificationPage> list({int page = 1, int perPage = 20}) async {
    final path = Uri(
      path: '/notifications',
      queryParameters: {
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    ).toString();
    final payload = await _apiClient.get(path);

    final raw = payload['data'];
    final notifications = raw is List
        ? raw
              .whereType<Map>()
              .map((item) => _notificationFromJson(_normalize(item)))
              .where((item) => item.id.isNotEmpty)
              .toList(growable: false)
        : const <MahjNotification>[];

    final meta = payload['meta'] is Map
        ? _normalize(payload['meta'] as Map)
        : const <String, dynamic>{};

    return NotificationPage(
      notifications: notifications,
      page: _readInt(meta['page'], page),
      hasMore: meta['has_more'] == true,
      unreadCount: _readInt(meta['unread_count'], 0),
    );
  }

  Future<int> unreadCount() async {
    final payload = await _apiClient.get('/notifications/unread-count');
    return _readInt(payload['unread_count'], 0);
  }

  Future<NotificationReadResult> markRead(String notificationId) async {
    final payload = await _apiClient.patch(
      '/notifications/$notificationId/read',
    );
    final raw = payload['notification'];
    if (raw is! Map) {
      throw const FormatException(
        'Notification response is missing notification data.',
      );
    }

    return NotificationReadResult(
      notification: _notificationFromJson(_normalize(raw)),
      unreadCount: _readInt(payload['unread_count'], 0),
    );
  }

  Future<NotificationPreferences> loadSettings() async {
    final payload = await _apiClient.get('/notification-settings');
    final raw = payload['settings'];
    return _preferencesFromJson(
      raw is Map ? _normalize(raw) : const <String, dynamic>{},
    );
  }

  Future<NotificationPreferences> saveSettings(
    NotificationPreferences preferences,
  ) async {
    final payload = await _apiClient.put(
      '/notification-settings',
      body: {
        'new_games_nearby': preferences.newGamesNearby,
        'game_invitations': preferences.gameInvitations,
        'players_joining_my_game': preferences.playersJoiningMyGame,
        'game_confirmations': preferences.gameConfirmations,
        'game_reminders': preferences.gameReminders,
        'schedule_changes': preferences.scheduleChanges,
        'new_messages': preferences.newMessages,
        'subscription_updates': preferences.subscriptionUpdates,
      },
    );
    final raw = payload['settings'];
    return _preferencesFromJson(
      raw is Map ? _normalize(raw) : const <String, dynamic>{},
    );
  }

  MahjNotification _notificationFromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? _normalize(json['data'] as Map)
        : const <String, dynamic>{};
    final createdAt =
        DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
        DateTime.now();

    return MahjNotification(
      id: json['id']?.toString() ?? '',
      type: _typeFromApi(json['type']?.toString()),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      createdAt: createdAt,
      isRead: json['is_read'] == true,
      relatedMatchId: json['related_match_id']?.toString(),
      relatedUserId: json['related_user_id']?.toString(),
      relatedInvitationId: data['invitation_id']?.toString(),
    );
  }

  NotificationPreferences _preferencesFromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      newGamesNearby: json['new_games_nearby'] != false,
      gameInvitations: json['game_invitations'] != false,
      playersJoiningMyGame: json['players_joining_my_game'] != false,
      gameConfirmations: json['game_confirmations'] != false,
      gameReminders: json['game_reminders'] != false,
      scheduleChanges: json['schedule_changes'] != false,
      newMessages: json['new_messages'] != false,
      subscriptionUpdates: json['subscription_updates'] != false,
    );
  }

  MahjNotificationType _typeFromApi(String? value) {
    return switch (value) {
      'nearby_match' => MahjNotificationType.nearbyMatch,
      'player_joined' => MahjNotificationType.playerJoined,
      'match_invite' => MahjNotificationType.matchInvite,
      'match_confirmed' => MahjNotificationType.matchConfirmed,
      'match_cancelled' => MahjNotificationType.matchCancelled,
      'schedule_changed' => MahjNotificationType.scheduleChanged,
      'chat_message' => MahjNotificationType.chatMessage,
      'game_reminder' => MahjNotificationType.gameReminder,
      'subscription_update' => MahjNotificationType.subscriptionUpdate,
      _ => MahjNotificationType.nearbyMatch,
    };
  }

  int _readInt(dynamic value, int fallback) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Map<String, dynamic> _normalize(Map value) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
}
