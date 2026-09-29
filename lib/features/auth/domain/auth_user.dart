import '../../../app/app_assets.dart';
import '../../profile/domain/profile_data.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.zipCode = '',
    this.city = '',
    this.state = '',
    this.bio = '',
    this.avatarUrl,
    this.upcomingMatchCount = 0,
    this.completedMatchCount = 0,
    this.unreadNotificationCount = 0,
    this.unreadMessageCount = 0,
    this.googleConnected = false,
    this.appleConnected = false,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    int readInt(String key) {
      final value = json[key];
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return AuthUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      zipCode: json['zip_code']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      upcomingMatchCount: readInt('upcoming_match_count'),
      completedMatchCount: readInt('completed_match_count'),
      unreadNotificationCount: readInt('unread_notification_count'),
      unreadMessageCount: readInt('unread_message_count'),
      googleConnected: json['google_connected'] == true,
      appleConnected: json['apple_connected'] == true,
    );
  }

  final String id;
  final String name;
  final String email;
  final String phone;
  final String zipCode;
  final String city;
  final String state;
  final String bio;
  final String? avatarUrl;
  final int upcomingMatchCount;
  final int completedMatchCount;
  final int unreadNotificationCount;
  final int unreadMessageCount;
  final bool googleConnected;
  final bool appleConnected;

  ProfileData toProfileData() {
    return ProfileData(
      id: id,
      name: name,
      email: email,
      address: city,
      postCode: zipCode,
      avatarAsset: AppAssets.demoAvatarOne,
      avatarUrl: avatarUrl,
      phone: phone,
      city: city,
      state: state,
      bio: bio,
      upcomingMatchCount: upcomingMatchCount,
      completedMatchCount: completedMatchCount,
      unreadNotificationCount: unreadNotificationCount,
      unreadMessageCount: unreadMessageCount,
    );
  }
}
