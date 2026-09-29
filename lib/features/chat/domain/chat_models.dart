enum ChatMessageType { message, system }

class ChatParticipant {
  const ChatParticipant({
    required this.id,
    required this.displayName,
    required this.avatarAsset,
    this.isOnline = false,
  });

  final String id;
  final String displayName;
  final String avatarAsset;
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
  });

  final String id;
  final String matchId;
  final String? senderId;
  final String? senderName;
  final String? senderAvatarAsset;
  final String text;
  final DateTime timestamp;
  final ChatMessageType type;

  bool isMine(String currentUserId) {
    return type == ChatMessageType.message && senderId == currentUserId;
  }
}
