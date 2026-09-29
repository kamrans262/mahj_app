import '../../../app/app_assets.dart';
import '../../home/data/home_preview_data.dart';
import '../domain/player_profile_data.dart';

abstract final class PlayerProfilePreviewData {
  static PlayerProfileData forIdentity({
    required String id,
    required String displayName,
    required String avatarAsset,
  }) {
    final home = HomePreviewData.create();
    final normalizedId = id.toLowerCase();

    final resolved = switch (normalizedId) {
      'austen' => (
        name: 'Austen Parker',
        email: 'auste54@gmail.com',
        address: 'Central City Park',
        postCode: '10001',
        matchesPlayed: 12,
        matchesHosted: 12,
        attendance: 96,
        memberSince: '12',
      ),
      'alex' => (
        name: 'Alex Turner',
        email: 'alex.turner@gmail.com',
        address: 'Central City Park',
        postCode: '10001',
        matchesPlayed: 18,
        matchesHosted: 7,
        attendance: 94,
        memberSince: '18',
      ),
      'robert' => (
        name: 'Robert Miles',
        email: 'robert.miles@gmail.com',
        address: 'Central City Park',
        postCode: '10001',
        matchesPlayed: 9,
        matchesHosted: 3,
        attendance: 91,
        memberSince: '8',
      ),
      _ => (
        name: displayName,
        email: '${normalizedId.isEmpty ? 'player' : normalizedId}@example.com',
        address: 'Central City Park',
        postCode: '10001',
        matchesPlayed: 12,
        matchesHosted: 4,
        attendance: 95,
        memberSince: '12',
      ),
    };

    return PlayerProfileData(
      id: id,
      name: resolved.name,
      email: resolved.email,
      address: resolved.address,
      postCode: resolved.postCode,
      avatarAsset: avatarAsset.isEmpty ? AppAssets.demoAvatarOne : avatarAsset,
      matchesPlayed: resolved.matchesPlayed,
      matchesHosted: resolved.matchesHosted,
      attendancePercent: resolved.attendance,
      memberSinceLabel: resolved.memberSince,
      mutualGames: List.unmodifiable(home.nearbyMatches),
    );
  }

  static PlayerProfileData get demo => forIdentity(
    id: 'austen',
    displayName: 'Austen Parker',
    avatarAsset: AppAssets.demoAvatarOne,
  );
}
