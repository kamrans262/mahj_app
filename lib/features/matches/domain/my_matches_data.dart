import '../../home/domain/home_match.dart';

enum MyMatchesTab { upcoming, createdByMe, invites }

class MyMatchesItem {
  const MyMatchesItem({
    required this.match,
    required this.sportImageAsset,
    this.markerNormalizedX,
    this.markerNormalizedY,
    this.invitationId,
    this.inviterName,
  });

  final HomeMatch match;
  final String sportImageAsset;
  final double? markerNormalizedX;
  final double? markerNormalizedY;
  final String? invitationId;
  final String? inviterName;

  bool get hasLocationPreview =>
      markerNormalizedX != null && markerNormalizedY != null;
}

class MyMatchesData {
  const MyMatchesData({
    required this.unreadNotificationCount,
    required this.unreadMessageCount,
    required this.upcoming,
    required this.createdByMe,
    required this.invites,
  });

  final int unreadNotificationCount;
  final int unreadMessageCount;
  final List<MyMatchesItem> upcoming;
  final List<MyMatchesItem> createdByMe;
  final List<MyMatchesItem> invites;

  List<MyMatchesItem> forTab(MyMatchesTab tab) {
    return switch (tab) {
      MyMatchesTab.upcoming => upcoming,
      MyMatchesTab.createdByMe => createdByMe,
      MyMatchesTab.invites => invites,
    };
  }
}
