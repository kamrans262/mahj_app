import 'package:flutter/material.dart';

import '../../../app/app_scroll_behavior.dart';
import '../../../app/theme/app_colors.dart';
import '../../home/data/home_preview_data.dart';
import '../../home/domain/home_data.dart';
import '../../home/domain/home_match.dart';
import '../../home/presentation/home_screen.dart';
import '../../home/presentation/widgets/app_bottom_navigation.dart';
import '../../map/presentation/map_screen.dart';
import '../../matches/data/match_repository.dart';
import '../../matches/domain/my_matches_data.dart';
import '../../matches/presentation/my_matches_screen.dart';
import '../../profile/data/profile_preview_data.dart';
import '../../profile/domain/profile_data.dart';
import '../../profile/presentation/profile_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({
    super.key,
    this.initialIndex = 0,
    this.initialProfileData,
    this.matchRepository,
    this.onNearbyViewAll,
    this.onCreateMatch,
    this.onMatchTap,
    this.onMyMatchesMatchTap,
    this.onMyMatchesInvitationTap,
    this.onNotificationTap,
    this.onMessageTap,
    this.onProfileSettingsTap,
    this.onProfileFavoritesTap,
    this.onEditProfile,
    this.onEditProfileRequest,
  });

  final int initialIndex;
  final ProfileData? initialProfileData;
  final MatchRepository? matchRepository;
  final VoidCallback? onNearbyViewAll;
  final VoidCallback? onCreateMatch;
  final ValueChanged<HomeMatch>? onMatchTap;
  final void Function(MyMatchesItem item, MyMatchesTab tab)?
  onMyMatchesMatchTap;
  final ValueChanged<MyMatchesItem>? onMyMatchesInvitationTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onProfileSettingsTap;
  final VoidCallback? onProfileFavoritesTap;
  final VoidCallback? onEditProfile;
  final Future<ProfileData?> Function(ProfileData profile)?
  onEditProfileRequest;

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;
  late ProfileData _profileData;
  bool _homeOverlayOpen = false;
  MyMatchesTab _myMatchesTab = MyMatchesTab.upcoming;
  List<HomeMatch> _liveMatches = const [];

  @override
  void initState() {
    super.initState();
    _currentIndex = _isSupportedIndex(widget.initialIndex)
        ? widget.initialIndex
        : 0;
    _profileData = widget.initialProfileData ?? ProfilePreviewData.currentUser;

    if (widget.matchRepository != null) {
      _refreshMatches();
    }
  }

  bool _isSupportedIndex(int index) => index >= 0 && index <= 3;

  void _selectTab(int index) {
    if (!_isSupportedIndex(index) || index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
      if (index != 0) {
        _homeOverlayOpen = false;
      }
    });
  }

  void _setHomeOverlayVisible(bool visible) {
    if (_currentIndex != 0 || _homeOverlayOpen == visible) return;
    setState(() => _homeOverlayOpen = visible);
  }

  void _rememberMyMatchesTab(MyMatchesTab tab) {
    _myMatchesTab = tab;
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  HomeData get _homeData {
    if (widget.matchRepository == null) {
      return HomePreviewData.create();
    }

    final upcoming = _liveMatches
        .where(
          (match) =>
              match.isCurrentUserJoined || match.isOwnedByCurrentUser,
        )
        .toList(growable: false);
    final nearby = _liveMatches
        .where(
          (match) =>
              !match.isCurrentUserJoined && !match.isOwnedByCurrentUser,
        )
        .toList(growable: false);

    return HomeData(
      greeting: _greeting,
      displayName: _profileData.name,
      subtitle: 'Find and join matches near you',
      location: _profileData.addressLine.isEmpty
          ? 'Set your location'
          : _profileData.addressLine,
      unreadNotificationCount: _profileData.unreadNotificationCount,
      unreadMessageCount: _profileData.unreadMessageCount,
      upcomingMatches: upcoming,
      nearbyMatches: nearby,
    );
  }

  Future<void> _refreshMatches() async {
    final repository = widget.matchRepository;
    if (repository == null) return;

    try {
      final matches = await repository.list();
      if (!mounted) return;
      setState(() => _liveMatches = matches);
    } catch (_) {
      // Keep the current list visible. Home pull-to-refresh can retry.
    }
  }

  Future<void> _joinHomeMatch(HomeMatch match) async {
    final repository = widget.matchRepository;
    if (repository == null) return;

    final updated = await repository.join(match.id);
    if (!mounted) return;

    setState(() {
      _liveMatches = _liveMatches
          .map((item) => item.id == updated.id ? updated : item)
          .toList(growable: false);
    });
  }

  void _requestEditProfile() {
    final request = widget.onEditProfileRequest;
    if (request == null) {
      widget.onEditProfile?.call();
      return;
    }

    request(_profileData).then((updated) {
      if (!mounted || updated == null) return;
      setState(() => _profileData = updated);
    });
  }

  Widget _buildActivePage() {
    switch (_currentIndex) {
      case 1:
        return MapScreen(
          key: const ValueKey('main-navigation-map'),
          onBack: () => _selectTab(0),
          onViewDetails: widget.onMatchTap,
        );
      case 2:
        return MyMatchesScreen(
          key: const ValueKey('main-navigation-my-matches'),
          initialTab: _myMatchesTab,
          onTabChanged: _rememberMyMatchesTab,
          onMatchTap: widget.onMyMatchesMatchTap,
          onInvitationTap: widget.onMyMatchesInvitationTap,
          onNotificationTap: widget.onNotificationTap,
          onMessageTap: widget.onMessageTap,
        );
      case 3:
        return ProfileScreen(
          key: const ValueKey('main-navigation-profile'),
          data: _profileData,
          onNotificationTap: widget.onNotificationTap,
          onMessageTap: widget.onMessageTap,
          onSettingsTap: widget.onProfileSettingsTap,
          onFavoritesTap: widget.onProfileFavoritesTap,
          onEditProfile: _requestEditProfile,
        );
      case 0:
      default:
        return HomeScreen(
          key: const ValueKey('main-navigation-home'),
          data: _homeData,
          onNearbyViewAll: widget.onNearbyViewAll,
          onMatchTap: widget.onMatchTap,
          onJoinMatch: widget.matchRepository == null ? null : _joinHomeMatch,
          onCreateMatch: widget.onCreateMatch,
          onRefresh: widget.matchRepository == null ? null : _refreshMatches,
          showBottomNavigation: false,
          showCreateFab: false,
          onFilterVisibilityChanged: _setHomeOverlayVisible,
          onNotificationTap: widget.onNotificationTap,
          onMessageTap: widget.onMessageTap,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showCreateAction =
        (_currentIndex == 0 || _currentIndex == 2) && !_homeOverlayOpen;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ScrollConfiguration(
        behavior: const AppScrollBehavior(),
        child: _buildActivePage(),
      ),
      floatingActionButton: showCreateAction
          ? FloatingActionButton(
              heroTag: 'main-shell-create-match-fab',
              onPressed: widget.onCreateMatch,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              tooltip: 'Create match',
              child: const Icon(Icons.add, size: 30),
            )
          : null,
      bottomNavigationBar: _homeOverlayOpen
          ? null
          : AppBottomNavigation(currentIndex: _currentIndex, onTap: _selectTab),
    );
  }
}
