import '../../../app/app_assets.dart';
import '../../../core/network/api_client.dart';
import '../domain/chat_models.dart';

class ChatRepository {
  const ChatRepository({required ApiClient apiClient}) : this._(apiClient);

  const ChatRepository._(this._apiClient);

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
    final meta = metaRaw is Map
        ? _normalize(metaRaw)
        : const <String, dynamic>{};

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

  Future<List<ChatParticipant>> searchUsers(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const <ChatParticipant>[];

    final path = Uri(
      path: '/users/search',
      queryParameters: {'q': trimmed},
    ).toString();
    final payload = await _apiClient.get(path);
    final raw = payload['data'];
    if (raw is! List) return const <ChatParticipant>[];

    return raw
        .whereType<Map>()
        .map((item) {
          final json = _normalize(item);
          return ChatParticipant(
            id: json['id']?.toString() ?? '',
            displayName: json['name']?.toString() ?? 'Player',
            avatarAsset: AppAssets.bottomProfileIcon,
            avatarUrl: json['avatar_url']?.toString(),
          );
        })
        .where((participant) => participant.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<DirectChatSummary>> listDirectChats() async {
    final payload = await _apiClient.get('/direct-chats');
    final raw = payload['data'];
    if (raw is! List) return const <DirectChatSummary>[];

    return raw
        .whereType<Map>()
        .map((item) => _directChatSummaryFromJson(_normalize(item)))
        .whereType<DirectChatSummary>()
        .toList(growable: false);
  }

  Future<DirectChatSummary> startDirectChat(String playerId) async {
    final payload = await _apiClient.post('/direct-chats/$playerId');
    final raw = payload['conversation'];
    if (raw is! Map) {
      throw const FormatException('Direct chat response is missing conversation data.');
    }

    final summary = _directChatSummaryFromJson(_normalize(raw));
    if (summary == null) {
      throw const FormatException('Direct chat response is invalid.');
    }
    return summary;
  }

  Future<DirectChatPage> loadDirect(
    String conversationId, {
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
      path: '/direct-chats/$conversationId',
      queryParameters: params,
    ).toString();
    final payload = await _apiClient.get(path);

    final conversationRaw = payload['conversation'];
    if (conversationRaw is! Map) {
      throw const FormatException('Direct chat response is missing conversation data.');
    }

    final conversation = _normalize(conversationRaw);
    final participant = _participantFromJson(conversation['other_user']);
    if (participant == null) {
      throw const FormatException('Direct chat response is missing player data.');
    }

    final messagesRaw = payload['messages'];
    final messages = messagesRaw is List
        ? messagesRaw
              .whereType<Map>()
              .map((item) => _directMessageFromJson(_normalize(item)))
              .where((message) => message.id.isNotEmpty)
              .toList(growable: false)
        : const <ChatMessage>[];

    final metaRaw = payload['meta'];
    final meta = metaRaw is Map
        ? _normalize(metaRaw)
        : const <String, dynamic>{};

    return DirectChatPage(
      participant: participant,
      messages: messages,
      hasMoreOlder: meta['has_more_older'] == true,
    );
  }

  Future<ChatMessage> sendDirect(
    String conversationId,
    String text,
  ) async {
    final payload = await _apiClient.post(
      '/direct-chats/$conversationId/messages',
      body: {'text': text},
    );

    final raw = payload['message'];
    if (raw is! Map) {
      throw const FormatException('Direct chat response is missing message data.');
    }

    return _directMessageFromJson(_normalize(raw));
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

  DirectChatSummary? _directChatSummaryFromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final participant = _participantFromJson(json['other_user']);
    if (id.isEmpty || participant == null) return null;

    final lastRaw = json['last_message'];
    final last = lastRaw is Map ? _normalize(lastRaw) : null;
    final updatedAt = DateTime.tryParse(json['updated_at']?.toString() ?? '');

    return DirectChatSummary(
      id: id,
      participant: participant,
      lastMessageText: last?['text']?.toString(),
      updatedAt: updatedAt?.toLocal(),
    );
  }

  ChatParticipant? _participantFromJson(dynamic raw) {
    if (raw is! Map) return null;
    final json = _normalize(raw);
    final id = json['id']?.toString() ?? '';
    if (id.isEmpty) return null;

    return ChatParticipant(
      id: id,
      displayName: json['name']?.toString() ?? 'Player',
      avatarAsset: AppAssets.bottomProfileIcon,
      avatarUrl: json['avatar_url']?.toString(),
      isOnline: json['is_online'] == true,
    );
  }

  ChatMessage _directMessageFromJson(Map<String, dynamic> json) {
    final senderRaw = json['sender'];
    final sender = senderRaw is Map
        ? _normalize(senderRaw)
        : const <String, dynamic>{};

    final parsedTimestamp = DateTime.tryParse(
      json['created_at']?.toString() ?? '',
    );
    final conversationId = json['conversation_id']?.toString() ?? '';

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      matchId: 'direct-$conversationId',
      senderId: sender['id']?.toString(),
      senderName: sender['name']?.toString(),
      senderAvatarAsset: sender.isEmpty ? null : AppAssets.bottomProfileIcon,
      senderAvatarUrl: sender['avatar_url']?.toString(),
      text: json['text']?.toString() ?? '',
      timestamp: (parsedTimestamp ?? DateTime.now()).toLocal(),
      type: ChatMessageType.message,
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
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
}
