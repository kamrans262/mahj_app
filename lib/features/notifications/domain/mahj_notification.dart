enum MahjNotificationType {
  nearbyMatch,
  playerJoined,
  matchInvite,
  matchAccepted,
  matchCancelled,
  matchConfirmed,
  scheduleChanged,
  chatMessage,
  gameReminder,
  subscriptionUpdate,
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
    this.relatedInvitationId,
  });

  final String id;
  final MahjNotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? relatedMatchId;
  final String? relatedUserId;
  final String? relatedInvitationId;

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
      relatedInvitationId: relatedInvitationId,
    );
  }
}
