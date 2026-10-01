import '../../../app/app_assets.dart';
import '../../../core/network/api_client.dart';
import '../domain/chat_models.dart';

class ChatRepository {
  const ChatRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<MatchChatPage> load(
    String matchId, {
    String? beforeId,
    String? afterId,
    int limit = 30,
  }) async {
    final params = <String, String>{'limit': limit.toString()};

    if (beforeId != null && beforeId.isNotEmpty) {
      params['before_id'] = beforeId;
    }
    if (afterId != null && afterId.isNotEmpty) {
      params['after_id'] = afterId;
    }

    final path = Uri(
      path: '/matches/$matchId/chat',
      queryParameters: params,
    ).toString();
    final payload = await _apiClient.get(path);

    final participantsRaw = payload['participants'];
    final participants = participantsRaw is List
        ? participantsRaw
              .whereType<Map>()
              .map((item) {
                final json = _normalize(item);
                return ChatParticipant(
                  id: json['id']?.toString() ?? '',
                  displayName: json['name']?.toString() ?? 'Player',
                  avatarAsset: AppAssets.bottomProfileIcon,
                  avatarUrl: json['avatar_url']?.toString(),
                  isOnline: json['is_online'] == true,
                );
              })
              .where((participant) => participant.id.isNotEmpty)
              .toList(growable: false)
        : const <ChatParticipant>[];

    final messagesRaw = payload['messages'];
    final messages = messagesRaw is List
        ? messagesRaw
              .whereType<Map>()
              .map((item) => _messageFromJson(_normalize(item)))
              .where((message) => message.id.isNotEmpty)
              .toList(growable: false)
        : const <ChatMessage>[];

    final metaRaw = payload['meta'];
    final meta = metaRaw is Map ? _normalize(metaRaw) : const <String, dynamic>{};

    return MatchChatPage(
      participants: participants,
      messages: messages,
      hasMoreOlder: meta['has_more_older'] == true,
      canSend: meta['can_send'] == true,
    );
  }

  Future<ChatMessage> send(String matchId, String text) async {
    final payload = await _apiClient.post(
      '/matches/$matchId/chat/messages',
      body: {'text': text},
    );

    final raw = payload['message'];
    if (raw is! Map) {
      throw const FormatException('Chat response is missing message data.');
    }

    return _messageFromJson(_normalize(raw));
  }

  Future<void> reportPlayer({
    required String playerId,
    required String reasonId,
    required String notes,
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

  ChatMessage _messageFromJson(Map<String, dynamic> json) {
    final senderRaw = json['sender'];
    final sender = senderRaw is Map
        ? _normalize(senderRaw)
        : const <String, dynamic>{};

    final parsedTimestamp = DateTime.tryParse(
      json['created_at']?.toString() ?? '',
    );

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      matchId: json['match_id']?.toString() ?? '',
      senderId: sender['id']?.toString(),
      senderName: sender['name']?.toString(),
      senderAvatarAsset: sender.isEmpty ? null : AppAssets.bottomProfileIcon,
      senderAvatarUrl: sender['avatar_url']?.toString(),
      text: json['text']?.toString() ?? '',
      timestamp: (parsedTimestamp ?? DateTime.now()).toLocal(),
      type: json['type']?.toString() == 'system'
          ? ChatMessageType.system
          : ChatMessageType.message,
    );
  }

  Map<String, dynamic> _normalize(Map value) {
    return value.map(
      (key, item) => MapEntry(key.toString(), item),
    );
  }
}
