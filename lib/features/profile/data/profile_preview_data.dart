import '../../../app/app_assets.dart';
import '../domain/profile_data.dart';

abstract final class ProfilePreviewData {
  static const ProfileData currentUser = ProfileData(
    id: 'demo-current-user',
    name: 'Austen Parker',
    email: 'auste54@gmail.com',
    address: 'Central City Park',
    postCode: '10001',
    avatarAsset: AppAssets.demoAvatarOne,
    phone: '',
    city: 'Central City Park',
    state: '',
    bio: '',
    upcomingMatchCount: 12,
    completedMatchCount: 12,
    unreadNotificationCount: 3,
    unreadMessageCount: 3,
  );
}
