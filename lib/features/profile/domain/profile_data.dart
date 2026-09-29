class ProfileData {
  const ProfileData({
    required this.id,
    required this.name,
    required this.email,
    required this.address,
    required this.postCode,
    required this.avatarAsset,
    required this.upcomingMatchCount,
    required this.completedMatchCount,
    required this.unreadNotificationCount,
    required this.unreadMessageCount,
    this.avatarUrl,
    this.phone = '',
    this.city = '',
    this.state = '',
    this.bio = '',
  });

  final String id;
  final String name;
  final String email;
  final String address;
  final String postCode;
  final String avatarAsset;
  final String? avatarUrl;
  final String phone;
  final String city;
  final String state;
  final String bio;
  final int upcomingMatchCount;
  final int completedMatchCount;
  final int unreadNotificationCount;
  final int unreadMessageCount;

  String get addressLine {
    final trimmedAddress = address.trim();
    final trimmedPostCode = postCode.trim();
    if (trimmedAddress.isEmpty) return trimmedPostCode;
    if (trimmedPostCode.isEmpty) return trimmedAddress;
    return '$trimmedAddress . $trimmedPostCode';
  }

  ProfileData copyWith({
    String? id,
    String? name,
    String? email,
    String? address,
    String? postCode,
    String? avatarAsset,
    String? avatarUrl,
    String? phone,
    String? city,
    String? state,
    String? bio,
    int? upcomingMatchCount,
    int? completedMatchCount,
    int? unreadNotificationCount,
    int? unreadMessageCount,
  }) {
    return ProfileData(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      address: address ?? this.address,
      postCode: postCode ?? this.postCode,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      state: state ?? this.state,
      bio: bio ?? this.bio,
      upcomingMatchCount: upcomingMatchCount ?? this.upcomingMatchCount,
      completedMatchCount: completedMatchCount ?? this.completedMatchCount,
      unreadNotificationCount:
          unreadNotificationCount ?? this.unreadNotificationCount,
      unreadMessageCount: unreadMessageCount ?? this.unreadMessageCount,
    );
  }
}
