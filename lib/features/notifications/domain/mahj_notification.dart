enum MahjNotificationType {
  nearbyMatch,
  matchInvite,
  matchAccepted,
  matchCancelled,
  matchConfirmed,
  chatMessage,
  matchCompleted,
  scoreSubmitted,
}

class MahjNotification {
  const MahjNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.relatedMatchId,
    this.relatedUserId,
  });

  final String id;
  final MahjNotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? relatedMatchId;
  final String? relatedUserId;

  MahjNotification copyWith({bool? isRead}) {
    return MahjNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      relatedMatchId: relatedMatchId,
      relatedUserId: relatedUserId,
    );
  }
}
