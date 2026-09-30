enum MatchStatus { open, confirmed, cancelled, full, completed }

class HomeMatch {
  const HomeMatch({
    required this.id,
    required this.sportName,
    required this.location,
    required this.startsAt,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.status,
    this.sportIconAsset = '',
    this.sportIconKey = '',
    this.bannerAsset = '',
    this.isJoinable = true,
    this.venueName,
    this.hostUserId,
    this.hostName,
    this.notes,
    this.isPublic = true,
    this.isInviteOnly = false,
    this.isCurrentUserJoined = false,
    this.isOwnedByCurrentUser = false,
    this.canLeave = false,
    this.canCancel = false,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String sportName;
  final String location;
  final DateTime startsAt;
  final int currentPlayers;
  final int maxPlayers;
  final MatchStatus status;
  final String sportIconAsset;
  final String sportIconKey;
  final String bannerAsset;
  final bool isJoinable;
  final String? venueName;
  final String? hostUserId;
  final String? hostName;
  final String? notes;
  final bool isPublic;
  final bool isInviteOnly;
  final bool isCurrentUserJoined;
  final bool isOwnedByCurrentUser;
  final bool canLeave;
  final bool canCancel;
  final double? latitude;
  final double? longitude;

  bool get isFull => currentPlayers >= maxPlayers || status == MatchStatus.full;

  bool get isBackendMatch => int.tryParse(id) != null;

  factory HomeMatch.fromJson(Map<String, dynamic> json) {
    final host = json['host'];
    final hostMap = host is Map
        ? host.map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};

    return HomeMatch(
      id: json['id']?.toString() ?? '',
      sportName:
          json['name']?.toString() ?? json['sport_name']?.toString() ?? 'Match',
      location:
          json['location']?.toString() ??
          json['location_address']?.toString() ??
          '',
      startsAt:
          DateTime.tryParse(json['starts_at']?.toString() ?? '') ??
          DateTime.now(),
      currentPlayers: (json['current_players'] as num?)?.toInt() ?? 0,
      maxPlayers: (json['max_players'] as num?)?.toInt() ?? 4,
      status: _statusFromJson(json['status']?.toString()),
      isJoinable: json['can_join'] == true,
      sportIconKey: json['sport_icon_key']?.toString() ?? '',
      venueName: json['venue_name']?.toString(),
      hostUserId: hostMap['id']?.toString(),
      hostName: hostMap['name']?.toString(),
      notes: json['notes']?.toString(),
      isPublic: json['is_public'] != false,
      isInviteOnly: json['is_invite_only'] == true,
      isCurrentUserJoined: json['is_joined'] == true,
      isOwnedByCurrentUser: json['is_host'] == true,
      canLeave: json['can_leave'] == true,
      canCancel: json['can_cancel'] == true,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  HomeMatch copyWith({
    String? id,
    String? sportName,
    String? location,
    DateTime? startsAt,
    int? currentPlayers,
    int? maxPlayers,
    MatchStatus? status,
    String? sportIconAsset,
    String? sportIconKey,
    String? bannerAsset,
    bool? isJoinable,
    String? venueName,
    String? hostUserId,
    String? hostName,
    String? notes,
    bool? isPublic,
    bool? isInviteOnly,
    bool? isCurrentUserJoined,
    bool? isOwnedByCurrentUser,
    bool? canLeave,
    bool? canCancel,
    double? latitude,
    double? longitude,
  }) {
    return HomeMatch(
      id: id ?? this.id,
      sportName: sportName ?? this.sportName,
      location: location ?? this.location,
      startsAt: startsAt ?? this.startsAt,
      currentPlayers: currentPlayers ?? this.currentPlayers,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      status: status ?? this.status,
      sportIconAsset: sportIconAsset ?? this.sportIconAsset,
      sportIconKey: sportIconKey ?? this.sportIconKey,
      bannerAsset: bannerAsset ?? this.bannerAsset,
      isJoinable: isJoinable ?? this.isJoinable,
      venueName: venueName ?? this.venueName,
      hostUserId: hostUserId ?? this.hostUserId,
      hostName: hostName ?? this.hostName,
      notes: notes ?? this.notes,
      isPublic: isPublic ?? this.isPublic,
      isInviteOnly: isInviteOnly ?? this.isInviteOnly,
      isCurrentUserJoined: isCurrentUserJoined ?? this.isCurrentUserJoined,
      isOwnedByCurrentUser: isOwnedByCurrentUser ?? this.isOwnedByCurrentUser,
      canLeave: canLeave ?? this.canLeave,
      canCancel: canCancel ?? this.canCancel,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  static MatchStatus _statusFromJson(String? value) {
    return switch (value) {
      'confirmed' => MatchStatus.confirmed,
      'cancelled' => MatchStatus.cancelled,
      'full' => MatchStatus.full,
      'completed' => MatchStatus.completed,
      _ => MatchStatus.open,
    };
  }
}
