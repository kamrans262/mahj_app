import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/app_scroll_behavior.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../home/data/home_preload_store.dart';
import '../../home/data/home_preview_data.dart';
import '../../home/data/location_repository.dart';
import '../../home/data/match_discovery_store.dart';
import '../../home/domain/discovery_location.dart';
import '../../home/domain/home_data.dart';
import '../../home/domain/home_match.dart';
import '../../home/domain/featured_match_selector.dart';
import '../../home/domain/match_filters.dart';
import '../../home/presentation/home_screen.dart';
import '../../home/presentation/widgets/app_bottom_navigation.dart';
import '../../map/domain/map_match_marker.dart';
import '../../map/presentation/map_screen.dart';
import '../../matches/data/match_repository.dart';
import '../../matches/domain/my_matches_data.dart';
import '../../matches/presentation/my_matches_screen.dart';
import '../../notifications/data/notification_store.dart';
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
    this.notificationStore,
    this.onAuthenticatedReady,
    this.onUpcomingViewAll,
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
    this.onAvatarUpload,
    this.onAvatarRemove,
  });

  final int initialIndex;
  final ProfileData? initialProfileData;
  final HomePreloadStore? homePreloadStore;
  final MatchRepository? matchRepository;
  final MatchDiscoveryStore? discoveryStore;
  final LocationRepository? locationRepository;
  final NotificationStore? notificationStore;
  final Future<void> Function()? onAuthenticatedReady;
  final VoidCallback? onUpcomingViewAll;
  final VoidCallback? onNearbyViewAll;
  final VoidCallback? onCreateMatch;
  final Future<void> Function(HomeMatch)? onMatchTap;
  final Future<void> Function(MyMatchesItem item, MyMatchesTab tab)?
  onMyMatchesMatchTap;
  final Future<void> Function(MyMatchesItem item)? onMyMatchesInvitationTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onProfileSettingsTap;
  final VoidCallback? onProfileFavoritesTap;
  final VoidCallback? onEditProfile;
  final Future<ProfileData?> Function(ProfileData profile)?
  onEditProfileRequest;
  final Future<ProfileData> Function(List<int> bytes, String filename)? onAvatarUpload;
  final Future<ProfileData> Function()? onAvatarRemove;

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
  // The Home Upcoming Matches banner uses independent GPS-based 50-mile
  // results. Never share its origin or radius with Map/Nearby filters.
  List<HomeMatch> _bannerLocalMatches = const [];
  double? _bannerLatitude;
  double? _bannerLongitude;
  String _bannerCity = '';
  bool _bannerRequestedLocationPermission = false;
  Future<DiscoveryLocation?>? _bannerPendingLocationRequest;
  int _bannerRequestVersion = 0;
  late final MatchDiscoveryStore _discoveryStore;
  late final bool _ownsDiscoveryStore;
  bool _matchesLoading = false;
  MyMatchesData? _myMatchesData;
  bool _myMatchesLoading = false;
  String? _myMatchesError;
  double? _myMatchesOriginLatitude;
  double? _myMatchesOriginLongitude;
  Timer? _notificationRefreshTimer;

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
    widget.notificationStore?.addListener(_handleNotificationChanged);
    final authenticatedReady = widget.onAuthenticatedReady;
    if (authenticatedReady != null) {
      unawaited(authenticatedReady());
    }

    final notificationStore = widget.notificationStore;
    if (notificationStore != null) {
      unawaited(notificationStore.ensureLoaded());
      _notificationRefreshTimer = Timer.periodic(
        const Duration(seconds: 20),
        (_) => unawaited(notificationStore.refreshUnreadCount()),
      );
    }

    if (widget.matchRepository != null && preloaded == null) {
      unawaited(_initializeMatches());
    } else if (widget.matchRepository != null && _currentIndex == 0) {
      // Preloading provides discovery/global matches. Resolve the banner
      // location only while Home is being shown, not in the Map tab.
      unawaited(_refreshFeaturedBanner());
    }
    if (_currentIndex == 1) {
      unawaited(_ensureCurrentMapLocation());
    }
    if (widget.matchRepository != null &&
        (_currentIndex == 2 || _currentIndex == 3)) {
      _refreshMyMatches();
    }
  }

  @override
  void dispose() {
    _notificationRefreshTimer?.cancel();
    _discoveryStore.removeListener(_handleDiscoveryFiltersChanged);
    widget.notificationStore?.removeListener(_handleNotificationChanged);
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

  Future<void> _ensureCurrentMapLocation() async {
    var filters = _discoveryStore.filters;
    final locations = widget.locationRepository;

    if (locations == null ||
        !filters.usesCurrentLocation ||
        filters.hasCoordinates) {
      return;
    }

    try {
      final current =
          await locations.currentLocationIfGranted() ??
          await locations.currentLocation();

      if (!mounted) return;

      filters = filters.copyWith(
        selectedLocation: MatchFilters.defaultLocation,
        latitude: current.latitude,
        longitude: current.longitude,
      );
      _discoveryStore.update(filters, notify: false);
      setState(() {});
      await _refreshMatches();
    } catch (_) {
      // Keep the map usable even if device location is unavailable.
    }
  }

  void _handleDiscoveryFiltersChanged() {
    if (!mounted) return;
    setState(() {});
    _refreshMatches();
  }

  void _handleNotificationChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  int get _unreadNotificationCount =>
      widget.notificationStore?.unreadCount ??
      _profileData.unreadNotificationCount;

  ProfileData get _profileWithNotificationCount {
    final matches = _myMatchesData;
    return _profileData.copyWith(
      upcomingMatchCount:
          matches?.upcoming.length ?? _profileData.upcomingMatchCount,
      completedMatchCount:
          matches?.completed.length ?? _profileData.completedMatchCount,
      unreadNotificationCount: _unreadNotificationCount,
    );
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

    if (index == 1) {
      unawaited(_ensureCurrentMapLocation());
    } else if (index == 0 && widget.matchRepository != null) {
      // Refresh the user's actual location when returning Home. This only
      // affects the banner, not the selected discovery location.
      unawaited(_refreshFeaturedBanner());
    }

    if ((index == 2 || index == 3) && widget.matchRepository != null) {
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

  String get _greeting => 'Hello';

  String get _shortDisplayName {
    final name = _profileData.name.trim();
    if (name.isEmpty) return '';
    return name.split(RegExp(r'\s+')).first;
  }

  HomeData get _homeData {
    if (widget.matchRepository == null) {
      return HomePreviewData.create();
    }

    // Home banner selection is independent of Map/Nearby search filters:
    // admin-featured in the user's city/50 miles, other local matches, then
    // upcoming open matches from any location.
    final selection = FeaturedMatchSelector.selectHomeBanner(
      _bannerLocalMatches,
      _liveMatches,
      now: DateTime.now(),
      city: _bannerCity.isNotEmpty ? _bannerCity : _profileData.city,
      latitude: _bannerLatitude,
      longitude: _bannerLongitude,
    );
    final featured = selection.matches;
    final nearby = _discoveryMatches;

    return HomeData(
      greeting: _greeting,
      displayName: _shortDisplayName,
      subtitle: 'Find and join matches near you',
      location: _discoveryStore.filters.usesCurrentLocation
          ? (_profileData.addressLine.isEmpty
                ? MatchFilters.defaultLocation
                : _profileData.addressLine)
          : _discoveryStore.filters.selectedLocation,
      unreadNotificationCount: _unreadNotificationCount,
      unreadMessageCount: _profileData.unreadMessageCount,
      upcomingMatches: featured,
      nearbyMatches: nearby,
      isShowingOtherCities: selection.isOtherCitiesFallback,
    );
  }

  MyMatchesData get _resolvedMyMatchesData {
    final data = _myMatchesData;
    return MyMatchesData(
      unreadNotificationCount: _unreadNotificationCount,
      unreadMessageCount: _profileData.unreadMessageCount,
      upcoming: data?.upcoming ?? const <MyMatchesItem>[],
      createdByMe: data?.createdByMe ?? const <MyMatchesItem>[],
      invites: data?.invites ?? const <MyMatchesItem>[],
      completed: data?.completed ?? const <MyMatchesItem>[],
      cancelled: data?.cancelled ?? const <MyMatchesItem>[],
      upcomingPage: data?.upcomingPage ?? 1,
      createdByMePage: data?.createdByMePage ?? 1,
      invitesPage: data?.invitesPage ?? 1,
      completedPage: data?.completedPage ?? 1,
      cancelledPage: data?.cancelledPage ?? 1,
      hasMoreUpcoming: data?.hasMoreUpcoming ?? false,
      hasMoreCreatedByMe: data?.hasMoreCreatedByMe ?? false,
      hasMoreInvites: data?.hasMoreInvites ?? false,
      hasMoreCompleted: data?.hasMoreCompleted ?? false,
      hasMoreCancelled: data?.hasMoreCancelled ?? false,
    );
  }

  Future<({double latitude, double longitude})?>
  _resolveMyMatchesOrigin() async {
    final filters = _discoveryStore.filters;

    if (filters.hasCoordinates) {
      final latitude = filters.latitude;
      final longitude = filters.longitude;
      if (latitude != null && longitude != null) {
        _myMatchesOriginLatitude = latitude;
        _myMatchesOriginLongitude = longitude;
        return (latitude: latitude, longitude: longitude);
      }
    }

    if (_myMatchesOriginLatitude != null && _myMatchesOriginLongitude != null) {
      return (
        latitude: _myMatchesOriginLatitude!,
        longitude: _myMatchesOriginLongitude!,
      );
    }

    final locations = widget.locationRepository;
    if (locations == null) return null;

    final current = await locations.currentLocationIfGranted();
    if (current != null) {
      _myMatchesOriginLatitude = current.latitude;
      _myMatchesOriginLongitude = current.longitude;
      return (latitude: current.latitude, longitude: current.longitude);
    }

    final searchQueries = <String>[
      if (!filters.usesCurrentLocation) filters.selectedLocation.trim(),
      [
        _profileData.city.trim(),
        _profileData.state.trim(),
      ].where((value) => value.isNotEmpty).join(', '),
      _profileData.postCode.trim(),
      _profileData.address.trim(),
    ].where((value) => value.length >= 2).toSet();

    for (final query in searchQueries) {
      try {
        final results = await locations.search(query);
        if (results.isEmpty) continue;

        final resolved = results.first;
        _myMatchesOriginLatitude = resolved.latitude;
        _myMatchesOriginLongitude = resolved.longitude;

        return (latitude: resolved.latitude, longitude: resolved.longitude);
      } catch (_) {
        // Try the next available location source.
      }
    }

    try {
      final requested = await locations.currentLocation();
      _myMatchesOriginLatitude = requested.latitude;
      _myMatchesOriginLongitude = requested.longitude;

      return (latitude: requested.latitude, longitude: requested.longitude);
    } catch (_) {
      return null;
    }
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
      final origin = await _resolveMyMatchesOrigin();

      final data = await repository.listMyMatches(
        latitude: origin?.latitude,
        longitude: origin?.longitude,
      );
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

  Future<void> _loadMoreMyMatches(MyMatchesTab tab) async {
    final repository = widget.matchRepository;
    final current = _myMatchesData;
    if (repository == null || current == null || !current.hasMoreForTab(tab)) {
      return;
    }

    final nextPage = current.pageForTab(tab) + 1;
    final origin = await _resolveMyMatchesOrigin();

    final next = await repository.listMyMatches(
      latitude: origin?.latitude,
      longitude: origin?.longitude,
      upcomingPage: tab == MyMatchesTab.upcoming
          ? nextPage
          : current.upcomingPage,
      createdByMePage: tab == MyMatchesTab.createdByMe
          ? nextPage
          : current.createdByMePage,
      invitesPage: tab == MyMatchesTab.invites ? nextPage : current.invitesPage,
      completedPage: tab == MyMatchesTab.completed
          ? nextPage
          : current.completedPage,
      cancelledPage: tab == MyMatchesTab.cancelled
          ? nextPage
          : current.cancelledPage,
    );

    if (!mounted) return;
    setState(() {
      _myMatchesData = current.appendPage(next, tab);
    });
  }

  Future<void> _refreshFeaturedBanner() async {
    final repository = widget.matchRepository;
    if (repository == null) return;

    final version = ++_bannerRequestVersion;
    final locations = widget.locationRepository;
    DiscoveryLocation? origin;

    if (locations != null) {
      try {
        // Avoid a permission popup when location has already been granted.
        origin = await locations.currentLocationIfGranted();
      } catch (_) {
        // Fall back to the user's saved city/global matches.
      }

      if (origin == null) {
        final pending = _bannerPendingLocationRequest;
        if (pending != null) {
          // If a second Home refresh starts while the permission request is
          // still open, share the same GPS result instead of losing it.
          try {
            origin = await pending;
          } catch (_) {
            // The fallback will use the saved city/global matches.
          }
        } else if (!_bannerRequestedLocationPermission) {
          _bannerRequestedLocationPermission = true;
          final request = locations.currentLocation().then<DiscoveryLocation?>(
            (result) => result,
          );
          _bannerPendingLocationRequest = request;
          try {
            origin = await request;
          } catch (_) {
            // Location may be denied or unavailable. The banner still falls
            // back to matches elsewhere without changing Home/Map filters.
          } finally {
            if (identical(_bannerPendingLocationRequest, request)) {
              _bannerPendingLocationRequest = null;
            }
          }
        }
      }
    }

    if (!mounted || version != _bannerRequestVersion) return;

    var city = _profileData.city.trim();
    if (origin != null && locations != null) {
      try {
        final place = await locations.resolveMapTap(
          latitude: origin.latitude,
          longitude: origin.longitude,
        );
        if (place != null && place.city.trim().isNotEmpty) {
          city = place.city.trim();
        }
      } catch (_) {
        // Use the saved profile city when reverse geocoding is unavailable.
      }
    }

    if (!mounted || version != _bannerRequestVersion) return;

    // Both searches are banner-only and run concurrently. The city query
    // includes same-city matches without GPS coordinates or beyond 50 miles;
    // the radius query includes eligible games in neighboring cities.
    final localRequests = <Future<List<HomeMatch>>>[];
    if (origin != null) {
      final bannerFilters = MatchFilters.defaults().copyWith(
        radiusMiles: FeaturedMatchSelector.homeRadiusMiles,
        latitude: origin.latitude,
        longitude: origin.longitude,
        showOpenOnly: true,
        dateFilter: MatchDateFilter.any,
        sortOption: MatchSortOption.date,
      );
      localRequests.add(repository.list(filters: bannerFilters, discoverOnly: true));
    }

    final cityQuery = city.split(',').first.trim();
    if (cityQuery.length >= 2) {
      localRequests.add(repository.list(query: cityQuery, discoverOnly: true));
    }

    final localResponses = await Future.wait(
      localRequests.map((request) async {
        try {
          return await request;
        } catch (_) {
          // A failed local query must not stop the worldwide open fallback.
          return const <HomeMatch>[];
        }
      }),
    );

    if (!mounted || version != _bannerRequestVersion) return;
    setState(() {
      _bannerLocalMatches = localResponses
          .expand((matches) => matches)
          .toList(growable: false);
      _bannerLatitude = origin?.latitude;
      _bannerLongitude = origin?.longitude;
      _bannerCity = city;
    });
  }

  Future<void> _refreshMatches() async {
    final repository = widget.matchRepository;
    if (repository == null) return;

    // Refresh the independent Home banner only while Home is active. Map and
    // Nearby filter changes never initiate its GPS/50-mile searches.
    if (_currentIndex == 0) {
      unawaited(_refreshFeaturedBanner());
    }

    if (mounted) setState(() => _matchesLoading = true);
    try {
      final results = await Future.wait<List<HomeMatch>>([
        repository.list(),
        repository.list(filters: _discoveryStore.filters),
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

  Future<void> _openHomeMatchDetails(HomeMatch match) async {
    final callback = widget.onMatchTap;
    if (callback == null) return;

    await callback(match);
    if (!mounted || widget.matchRepository == null) return;

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

  Future<void> _changeAvatar() async {
    if (widget.onAvatarUpload == null || widget.onAvatarRemove == null) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.background,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Profile Photo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Upload / Change Photo'),
                onTap: () => Navigator.pop(sheetContext, 'upload'),
              ),
              if ((_profileData.avatarUrl ?? '').isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remove Photo'),
                  onTap: () => Navigator.pop(sheetContext, 'remove'),
                ),
              const SizedBox(height: 12),
              AppButton.primary(
                key: const ValueKey('profile-photo-cancel'),
                label: 'Cancel',
                onPressed: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;
    try {
      ProfileData? updated;
      if (action == 'remove') {
        updated = await widget.onAvatarRemove!();
      } else {
        final picked = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1400,
        );
        if (picked == null) return;
        updated = await widget.onAvatarUpload!(
          await picked.readAsBytes(),
          picked.name,
        );
      }
      if (!mounted) return;
      setState(() => _profileData = updated!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update profile photo. Please try again.')),
      );
    }
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
          onViewDetails: widget.onMatchTap == null
              ? null
              : (match) => unawaited(widget.onMatchTap!(match)),
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
              : {for (final tab in MyMatchesTab.values) tab: myMatchesError},
          onTabChanged: _rememberMyMatchesTab,
          onMatchTap: widget.onMyMatchesMatchTap == null
              ? null
              : (item, tab) async {
                  await widget.onMyMatchesMatchTap!(item, tab);
                  await _refreshMyMatches();
                },
          onInvitationTap: widget.onMyMatchesInvitationTap == null
              ? null
              : (item) {
                  final navigation = widget.onMyMatchesInvitationTap!(item);
                  unawaited(
                    navigation.whenComplete(() async {
                      if (!mounted) return;
                      await _refreshMyMatches();
                    }),
                  );
                },
          onRefresh: widget.matchRepository == null
              ? null
              : (_) => _refreshMyMatches(),
          onLoadMore: widget.matchRepository == null
              ? null
              : _loadMoreMyMatches,
          onNotificationTap: widget.onNotificationTap,
          onMessageTap: widget.onMessageTap,
        );
      case 3:
        return ProfileScreen(
          key: const ValueKey('main-navigation-profile'),
          data: _profileWithNotificationCount,
          onNotificationTap: widget.onNotificationTap,
          onMessageTap: widget.onMessageTap,
          onSettingsTap: widget.onProfileSettingsTap,
          onFavoritesTap: widget.onProfileFavoritesTap,
          onEditProfile: _requestEditProfile,
          onAvatarTap: _changeAvatar,
        );
      case 0:
      default:
        return HomeScreen(
          key: const ValueKey('main-navigation-home'),
          data: _homeData,
          onUpcomingViewAll: widget.onUpcomingViewAll,
          onNearbyViewAll: widget.onNearbyViewAll,
          onMatchTap: widget.onMatchTap == null
              ? null
              : (match) => unawaited(_openHomeMatchDetails(match)),
          onJoinMatch:
              widget.matchRepository == null || widget.onMatchTap == null
              ? null
              : _openHomeMatchDetails,
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
              shape: const CircleBorder(),
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
