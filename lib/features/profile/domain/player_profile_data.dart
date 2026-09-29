import '../../home/domain/home_match.dart';

class PlayerProfileData {
  const PlayerProfileData({
    required this.id,
    required this.name,
    required this.email,
    required this.address,
    required this.postCode,
    required this.avatarAsset,
    required this.matchesPlayed,
    required this.matchesHosted,
    required this.attendancePercent,
    required this.memberSinceLabel,
    required this.mutualGames,
    this.avatarUrl,
    this.canInvite = true,
    this.canReport = true,
    this.canBlock = true,
  });

  final String id;
  final String name;
  final String email;
  final String address;
  final String postCode;
  final String avatarAsset;
  final String? avatarUrl;
  final int matchesPlayed;
  final int matchesHosted;
  final int attendancePercent;
  final String memberSinceLabel;
  final List<HomeMatch> mutualGames;
  final bool canInvite;
  final bool canReport;
  final bool canBlock;

  String get addressLine {
    if (postCode.trim().isEmpty) return address;
    if (address.trim().isEmpty) return postCode;
    return '$address . $postCode';
  }
}

class PlayerReportRequest {
  const PlayerReportRequest({
    required this.playerId,
    required this.reasonId,
    required this.notes,
  });

  final String playerId;
  final String reasonId;
  final String notes;
}

class PlayerBlockRequest {
  const PlayerBlockRequest({required this.playerId, required this.reasonId});

  final String playerId;
  final String reasonId;
}
