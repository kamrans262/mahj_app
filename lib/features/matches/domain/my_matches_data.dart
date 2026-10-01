import '../../home/domain/home_match.dart';

enum MyMatchesTab { upcoming, createdByMe, invites, completed, cancelled }

class MyMatchesItem {
  const MyMatchesItem({
    required this.match,
    required this.sportImageAsset,
    this.markerNormalizedX,
    this.markerNormalizedY,
    this.invitationId,
    this.inviterName,
    this.inviterAvatarUrl,
  });

  final HomeMatch match;
  final String sportImageAsset;
  final double? markerNormalizedX;
  final double? markerNormalizedY;
  final String? invitationId;
  final String? inviterName;
  final String? inviterAvatarUrl;

  bool get hasLocationPreview =>
      match.hasCoordinates ||
      (markerNormalizedX != null && markerNormalizedY != null);
}

class MyMatchesData {
  const MyMatchesData({
    required this.unreadNotificationCount,
    required this.unreadMessageCount,
    required this.upcoming,
    required this.createdByMe,
    required this.invites,
    this.completed = const <MyMatchesItem>[],
    this.cancelled = const <MyMatchesItem>[],
    this.upcomingPage = 1,
    this.createdByMePage = 1,
    this.invitesPage = 1,
    this.completedPage = 1,
    this.cancelledPage = 1,
    this.hasMoreUpcoming = false,
    this.hasMoreCreatedByMe = false,
    this.hasMoreInvites = false,
    this.hasMoreCompleted = false,
    this.hasMoreCancelled = false,
  });

  final int unreadNotificationCount;
  final int unreadMessageCount;
  final List<MyMatchesItem> upcoming;
  final List<MyMatchesItem> createdByMe;
  final List<MyMatchesItem> invites;
  final List<MyMatchesItem> completed;
  final List<MyMatchesItem> cancelled;
  final int upcomingPage;
  final int createdByMePage;
  final int invitesPage;
  final int completedPage;
  final int cancelledPage;
  final bool hasMoreUpcoming;
  final bool hasMoreCreatedByMe;
  final bool hasMoreInvites;
  final bool hasMoreCompleted;
  final bool hasMoreCancelled;

  List<MyMatchesItem> forTab(MyMatchesTab tab) {
    return switch (tab) {
      MyMatchesTab.upcoming => upcoming,
      MyMatchesTab.createdByMe => createdByMe,
      MyMatchesTab.invites => invites,
      MyMatchesTab.completed => completed,
      MyMatchesTab.cancelled => cancelled,
    };
  }

  int pageForTab(MyMatchesTab tab) {
    return switch (tab) {
      MyMatchesTab.upcoming => upcomingPage,
      MyMatchesTab.createdByMe => createdByMePage,
      MyMatchesTab.invites => invitesPage,
      MyMatchesTab.completed => completedPage,
      MyMatchesTab.cancelled => cancelledPage,
    };
  }

  bool hasMoreForTab(MyMatchesTab tab) {
    return switch (tab) {
      MyMatchesTab.upcoming => hasMoreUpcoming,
      MyMatchesTab.createdByMe => hasMoreCreatedByMe,
      MyMatchesTab.invites => hasMoreInvites,
      MyMatchesTab.completed => hasMoreCompleted,
      MyMatchesTab.cancelled => hasMoreCancelled,
    };
  }

  MyMatchesData appendPage(MyMatchesData next, MyMatchesTab tab) {
    return MyMatchesData(
      unreadNotificationCount: next.unreadNotificationCount,
      unreadMessageCount: next.unreadMessageCount,
      upcoming: tab == MyMatchesTab.upcoming
          ? [...upcoming, ...next.upcoming]
          : upcoming,
      createdByMe: tab == MyMatchesTab.createdByMe
          ? [...createdByMe, ...next.createdByMe]
          : createdByMe,
      invites: tab == MyMatchesTab.invites
          ? [...invites, ...next.invites]
          : invites,
      completed: tab == MyMatchesTab.completed
          ? [...completed, ...next.completed]
          : completed,
      cancelled: tab == MyMatchesTab.cancelled
          ? [...cancelled, ...next.cancelled]
          : cancelled,
      upcomingPage: tab == MyMatchesTab.upcoming
          ? next.upcomingPage
          : upcomingPage,
      createdByMePage: tab == MyMatchesTab.createdByMe
          ? next.createdByMePage
          : createdByMePage,
      invitesPage: tab == MyMatchesTab.invites ? next.invitesPage : invitesPage,
      completedPage: tab == MyMatchesTab.completed
          ? next.completedPage
          : completedPage,
      cancelledPage: tab == MyMatchesTab.cancelled
          ? next.cancelledPage
          : cancelledPage,
      hasMoreUpcoming: tab == MyMatchesTab.upcoming
          ? next.hasMoreUpcoming
          : hasMoreUpcoming,
      hasMoreCreatedByMe: tab == MyMatchesTab.createdByMe
          ? next.hasMoreCreatedByMe
          : hasMoreCreatedByMe,
      hasMoreInvites: tab == MyMatchesTab.invites
          ? next.hasMoreInvites
          : hasMoreInvites,
      hasMoreCompleted: tab == MyMatchesTab.completed
          ? next.hasMoreCompleted
          : hasMoreCompleted,
      hasMoreCancelled: tab == MyMatchesTab.cancelled
          ? next.hasMoreCancelled
          : hasMoreCancelled,
    );
  }
}
