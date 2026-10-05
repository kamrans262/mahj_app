class PrivacySafetyUser {
  const PrivacySafetyUser({
    required this.id,
    required this.displayName,
    required this.username,
    required this.gamesCount,
    required this.avatarAsset,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String username;
  final int gamesCount;
  final String avatarAsset;
  final String? avatarUrl;

  String get secondaryLabel => '@$username · $gamesCount games';
}

class PrivacySafetyRule {
  const PrivacySafetyRule({required this.id, required this.label});

  final String id;
  final String label;
}

const List<PrivacySafetyRule> privacySafetyRules = [
  PrivacySafetyRule(id: 'respect', label: 'Be respectful to all players'),
  PrivacySafetyRule(id: 'punctual', label: 'Arrive on time'),
  PrivacySafetyRule(id: 'late-cancellation', label: 'No late cancellations'),
  PrivacySafetyRule(id: 'harassment', label: 'No hate speech or harassment'),
  PrivacySafetyRule(id: 'suspicious', label: 'Report suspicious behavior'),
  PrivacySafetyRule(id: 'community', label: 'Follow community rules'),
];

enum PrivacyReportStatus { pending, closed }

class PrivacyReportHistoryEntry {
  const PrivacyReportHistoryEntry({
    required this.id,
    required this.player,
    required this.status,
    this.createdAt,
    this.reason,
  });

  final String id;
  final PrivacySafetyUser player;
  final PrivacyReportStatus status;
  final DateTime? createdAt;
  final String? reason;

  String get statusLabel => switch (status) {
    PrivacyReportStatus.pending => 'Pending',
    PrivacyReportStatus.closed => 'Closed',
  };
}

class PrivacySafetyData {
  const PrivacySafetyData({
    required this.blockedUsers,
    required this.reportHistory,
  });

  final List<PrivacySafetyUser> blockedUsers;
  final List<PrivacyReportHistoryEntry> reportHistory;
}
