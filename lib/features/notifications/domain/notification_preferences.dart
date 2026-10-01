class NotificationPreferences {
  const NotificationPreferences({
    this.newGamesNearby = true,
    this.gameInvitations = true,
    this.playersJoiningMyGame = true,
    this.gameConfirmations = true,
    this.gameReminders = true,
    this.scheduleChanges = true,
    this.newMessages = true,
    this.subscriptionUpdates = true,
  });

  final bool newGamesNearby;
  final bool gameInvitations;
  final bool playersJoiningMyGame;
  final bool gameConfirmations;
  final bool gameReminders;
  final bool scheduleChanges;
  final bool newMessages;
  final bool subscriptionUpdates;

  NotificationPreferences copyWith({
    bool? newGamesNearby,
    bool? gameInvitations,
    bool? playersJoiningMyGame,
    bool? gameConfirmations,
    bool? gameReminders,
    bool? scheduleChanges,
    bool? newMessages,
    bool? subscriptionUpdates,
  }) {
    return NotificationPreferences(
      newGamesNearby: newGamesNearby ?? this.newGamesNearby,
      gameInvitations: gameInvitations ?? this.gameInvitations,
      playersJoiningMyGame:
          playersJoiningMyGame ?? this.playersJoiningMyGame,
      gameConfirmations: gameConfirmations ?? this.gameConfirmations,
      gameReminders: gameReminders ?? this.gameReminders,
      scheduleChanges: scheduleChanges ?? this.scheduleChanges,
      newMessages: newMessages ?? this.newMessages,
      subscriptionUpdates: subscriptionUpdates ?? this.subscriptionUpdates,
    );
  }
}
