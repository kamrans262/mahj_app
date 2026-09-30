import 'package:flutter/material.dart';

import '../../../app/app_scroll_behavior.dart';
import '../../../app/theme/app_colors.dart';
import '../../home/data/home_preload_store.dart';
import '../../home/data/home_preview_data.dart';
import '../../home/data/location_repository.dart';
import '../../home/data/match_discovery_store.dart';
import '../../home/domain/home_data.dart';
import '../../home/domain/home_match.dart';
import '../../home/domain/match_filters.dart';
import '../../home/presentation/home_screen.dart';
import '../../home/presentation/widgets/app_bottom_navigation.dart';
import '../../map/domain/map_match_marker.dart';
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
    this.homePreloadStore,
    this.matchRepository,
    this.discoveryStore,
    this.locationRepository,
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
  final HomePreloadStore? homePreloadStore;
  final MatchRepository? matchRepository;
  final MatchDiscoveryStore? discoveryStore;
  final LocationRepository? locationRepository;
  final VoidCallback? onNearbyViewAll;
  final VoidCallback? onCreateMatch;
  final ValueChanged<HomeMatch>? onMatchTap;
  final void Function(MyMatchesItem item, MyMatchesTab tab)?
  onMyMatchesMatchTap;
  final Future<void> Function(MyMatchesItem item)? onMyMatchesInvitationTap;
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
  List<HomeMatch> _discoveryMatches = const [];
  late final MatchDiscoveryStore _discoveryStore;
  late final bool _ownsDiscoveryStore;
  bool _matchesLoading = false;
  MyMatchesData? _myMatchesData;
  bool _myMatchesLoading = false;
  String? _myMatchesError;

  @override
  void initState() {
    super.initState();
    _currentIndex = _isSupportedIndex(widget.initialIndex)
        ? widget.initialIndex
        : 0;
    _profileData = widget.initialProfileData ?? ProfilePreviewData.currentUser;
    _ownsDiscoveryStore = widget.discoveryStore == null;
    _discoveryStore = widget.discoveryStore ?? MatchDiscoveryStore();

    final preloaded = widget.homePreloadStore?.snapshot;
    if (preloaded != null) {
      _liveMatches = preloaded.liveMatches;
      _discoveryMatches = preloaded.discoveryMatches;
      _discoveryStore.update(preloaded.filters, notify: false);
    }

    _discoveryStore.addListener(_handleDiscoveryFiltersChanged);

    if (widget.matchRepository != null && preloaded == null) {
      _initializeMatches();
    }
    if (widget.matchRepository != null && _currentIndex == 2) {
      _refreshMyMatches();
    }
  }

  @override
  void dispose() {
    _discoveryStore.removeListener(_handleDiscoveryFiltersChanged);
    if (_ownsDiscoveryStore) {
      _discoveryStore.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeMatches() async {
    var filters = _discoveryStore.filters;
    final locations = widget.locationRepository;

    if (locations != null &&
        filters.usesCurrentLocation &&
        !filters.hasCoordinates) {
      try {
        final current = await locations.currentLocation();
        filters = filters.copyWith(
          selectedLocation: current.label,
          latitude: current.latitude,
          longitude: current.longitude,
        );
        _discoveryStore.update(filters, notify: false);
      } catch (_) {
        // Discovery still works without a device coordinate; radius is simply
        // not applied until the user grants location or selects a city/ZIP.
      }
    }

    await _refreshMatches();
  }

  void _handleDiscoveryFiltersChanged() {
    if (!mounted) return;
    setState(() {});
    _refreshMatches();
  }

  Future<void> _applyDiscoveryFilters(MatchFilters filters) async {
    _discoveryStore.update(filters, notify: false);
    if (mounted) setState(() {});
    await _refreshMatches();
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

    if (index == 2 && widget.matchRepository != null) {
      _refreshMyMatches();
    }
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

    final featured = _liveMatches.where((match) => match.isFeatured).toList()
      ..sort((a, b) {
        final order = a.featuredOrder.compareTo(b.featuredOrder);
        if (order != 0) return order;
        return a.startsAt.compareTo(b.startsAt);
      });
    final nearby = _discoveryMatches;

    return HomeData(
      greeting: _greeting,
      displayName: _profileData.name,
      subtitle: 'Find and join matches near you',
      location: _discoveryStore.filters.usesCurrentLocation
          ? (_profileData.addressLine.isEmpty
                ? MatchFilters.defaultLocation
                : _profileData.addressLine)
          : _discoveryStore.filters.selectedLocation,
      unreadNotificationCount: _profileData.unreadNotificationCount,
      unreadMessageCount: _profileData.unreadMessageCount,
      upcomingMatches: featured,
      nearbyMatches: nearby,
    );
  }

  MyMatchesData get _resolvedMyMatchesData {
    final data = _myMatchesData;
    return MyMatchesData(
      unreadNotificationCount: _profileData.unreadNotificationCount,
      unreadMessageCount: _profileData.unreadMessageCount,
      upcoming: data?.upcoming ?? const <MyMatchesItem>[],
      createdByMe: data?.createdByMe ?? const <MyMatchesItem>[],
      invites: data?.invites ?? const <MyMatchesItem>[],
    );
  }

  Future<void> _refreshMyMatches() async {
    final repository = widget.matchRepository;
    if (repository == null) return;

    if (mounted) {
      setState(() {
        _myMatchesLoading = true;
        _myMatchesError = null;
      });
    }

    try {
      final data = await repository.listMyMatches();
      if (!mounted) return;
      setState(() => _myMatchesData = data);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _myMatchesError = 'Could not load your matches. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _myMatchesLoading = false);
    }
  }

  Future<void> _refreshMatches() async {
    final repository = widget.matchRepository;
    if (repository == null) return;

    if (mounted) setState(() => _matchesLoading = true);
    try {
      final results = await Future.wait<List<HomeMatch>>([
        repository.list(),
        repository.list(filters: _discoveryStore.filters, discoverOnly: true),
      ]);
      if (!mounted) return;
      setState(() {
        _liveMatches = results[0];
        _discoveryMatches = results[1];
      });
      widget.homePreloadStore?.update(
        liveMatches: results[0],
        discoveryMatches: results[1],
        filters: _discoveryStore.filters,
      );
    } catch (_) {
      // Keep the current list visible. Pull-to-refresh or filter changes retry.
    } finally {
      if (mounted) setState(() => _matchesLoading = false);
    }
  }

  Future<void> _joinHomeMatch(HomeMatch match) async {
    final repository = widget.matchRepository;
    if (repository == null) return;

    await repository.join(match.id);
    if (!mounted) return;
    await _refreshMatches();
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
        final markers = _discoveryMatches
            .where((match) => match.hasCoordinates)
            .map(MapMatchMarker.fromMatch)
            .toList(growable: false);
        return MapScreen(
          key: const ValueKey('main-navigation-map'),
          markers: markers,
          filters: _discoveryStore.filters,
          onBack: () => _selectTab(0),
          onViewDetails: widget.onMatchTap,
          onFiltersChanged: _applyDiscoveryFilters,
          isLoading: _matchesLoading,
          useLiveMap: widget.matchRepository != null,
        );
      case 2:
        final myMatchesError = _myMatchesError;
        return MyMatchesScreen(
          key: const ValueKey('main-navigation-my-matches'),
          data: widget.matchRepository == null ? null : _resolvedMyMatchesData,
          initialTab: _myMatchesTab,
          loadingTabs: _myMatchesLoading
              ? Set<MyMatchesTab>.from(MyMatchesTab.values)
              : const <MyMatchesTab>{},
          errorMessages: myMatchesError == null
              ? const <MyMatchesTab, String>{}
              : {
                  for (final tab in MyMatchesTab.values)
                    tab: myMatchesError,
                },
          onTabChanged: _rememberMyMatchesTab,
          onMatchTap: widget.onMyMatchesMatchTap,
          onInvitationTap: widget.onMyMatchesInvitationTap == null
              ? null
              : (item) async {
                  await widget.onMyMatchesInvitationTap!(item);
                  await _refreshMyMatches();
                },
          onRefresh: widget.matchRepository == null
              ? null
              : (_) => _refreshMyMatches(),
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
          onFiltersApplied: widget.matchRepository == null
              ? null
              : _applyDiscoveryFilters,
          initialFilters: _discoveryStore.filters,
          onLocationSearch: widget.locationRepository?.search,
          onCurrentLocation: widget.locationRepository?.currentLocation,
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
