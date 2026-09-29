import '../../../app/app_assets.dart';
import '../../home/domain/home_match.dart';
import '../domain/chat_models.dart';

abstract final class MatchChatPreviewData {
  static const String currentUserId = 'current-user';

  static List<ChatParticipant> participantsFor(HomeMatch _) {
    return const [
      ChatParticipant(
        id: 'austen',
        displayName: 'Austen',
        avatarAsset: AppAssets.demoAvatarOne,
        isOnline: true,
      ),
      ChatParticipant(
        id: 'alex',
        displayName: 'Alex',
        avatarAsset: AppAssets.demoAvatarTwo,
        isOnline: true,
      ),
      ChatParticipant(
        id: 'robert',
        displayName: 'Robert',
        avatarAsset: AppAssets.demoAvatarThree,
        isOnline: true,
      ),
      ChatParticipant(
        id: currentUserId,
        displayName: 'Tylor',
        avatarAsset: AppAssets.demoAvatarOne,
        isOnline: true,
      ),
    ];
  }

  static List<ChatMessage> messagesFor(HomeMatch match) {
    final base = DateTime(
      match.startsAt.year,
      match.startsAt.month,
      match.startsAt.day,
      18,
    );

    return [
      ChatMessage(
        id: '${match.id}-system-1',
        matchId: match.id,
        text: 'Alex joined the match',
        timestamp: base.subtract(const Duration(minutes: 35)),
        type: ChatMessageType.system,
      ),
      ChatMessage(
        id: '${match.id}-message-1',
        matchId: match.id,
        senderId: 'alex',
        senderName: 'Alex',
        senderAvatarAsset: AppAssets.demoAvatarTwo,
        text: 'Hey Everyone! Exited for the game',
        timestamp: base,
        type: ChatMessageType.message,
      ),
      ChatMessage(
        id: '${match.id}-message-2',
        matchId: match.id,
        senderId: currentUserId,
        senderName: 'You',
        senderAvatarAsset: AppAssets.demoAvatarOne,
        text: 'Hey Everyone! Exited for the game',
        timestamp: base,
        type: ChatMessageType.message,
      ),
      ChatMessage(
        id: '${match.id}-system-2',
        matchId: match.id,
        text: 'Jenny joined the match',
        timestamp: base.add(const Duration(minutes: 4)),
        type: ChatMessageType.system,
      ),
      ChatMessage(
        id: '${match.id}-system-3',
        matchId: match.id,
        text: 'Alex Confirmed the match',
        timestamp: base.add(const Duration(minutes: 8)),
        type: ChatMessageType.system,
      ),
      ChatMessage(
        id: '${match.id}-message-3',
        matchId: match.id,
        senderId: 'alex',
        senderName: 'Alex',
        senderAvatarAsset: AppAssets.demoAvatarTwo,
        text: 'See You guys soon',
        timestamp: base.add(const Duration(minutes: 12)),
        type: ChatMessageType.message,
      ),
    ];
  }
}
