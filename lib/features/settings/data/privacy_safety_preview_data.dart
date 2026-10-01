import '../../../app/app_assets.dart';
import '../domain/privacy_safety_data.dart';

abstract final class PrivacySafetyPreviewData {
  static const PrivacySafetyUser austen = PrivacySafetyUser(
    id: 'austen',
    displayName: 'Austen Parker',
    username: 'austn',
    gamesCount: 38,
    avatarAsset: AppAssets.demoAvatarOne,
  );

  static const PrivacySafetyUser alex = PrivacySafetyUser(
    id: 'alex',
    displayName: 'Alex Turner',
    username: 'alex',
    gamesCount: 24,
    avatarAsset: AppAssets.demoAvatarTwo,
  );

  static const List<PrivacySafetyUser> blockedUsers = [austen, alex];

  static const List<PrivacySafetyRule> rules = privacySafetyRules;

  static const List<PrivacyReportHistoryEntry> reportHistory = [
    PrivacyReportHistoryEntry(
      id: 'report-1',
      player: austen,
      status: PrivacyReportStatus.pending,
      reason: 'Inappropriate behavior',
    ),
    PrivacyReportHistoryEntry(
      id: 'report-2',
      player: alex,
      status: PrivacyReportStatus.closed,
      reason: 'Safety concern',
    ),
  ];
}
