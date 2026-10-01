enum ChatMessageType { message, system }

class ChatParticipant {
  const ChatParticipant({
    required this.id,
    required this.displayName,
    required this.avatarAsset,
    this.avatarUrl,
    this.isOnline = false,
  });

  final String id;
  final String displayName;
  final String avatarAsset;
  final String? avatarUrl;
  final bool isOnline;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.matchId,
    required this.text,
    required this.timestamp,
    required this.type,
    this.senderId,
    this.senderName,
    this.senderAvatarAsset,
    this.senderAvatarUrl,
  });

  final String id;
  final String matchId;
  final String? senderId;
  final String? senderName;
  final String? senderAvatarAsset;
  final String? senderAvatarUrl;
  final String text;
  final DateTime timestamp;
  final ChatMessageType type;

  bool isMine(String currentUserId) {
    return type == ChatMessageType.message && senderId == currentUserId;
  }
}

class MatchChatPage {
  const MatchChatPage({
    required this.participants,
    required this.messages,
    required this.hasMoreOlder,
    required this.canSend,
  });

  final List<ChatParticipant> participants;
  final List<ChatMessage> messages;
  final bool hasMoreOlder;
  final bool canSend;
}
