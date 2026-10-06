import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../data/home_preview_data.dart';
import '../domain/discovery_location.dart';
import '../domain/home_data.dart';
import '../domain/home_match.dart';
import '../domain/match_filters.dart';
import 'widgets/app_bottom_navigation.dart';
import 'widgets/featured_match_card.dart';
import 'widgets/home_filter_sheet.dart';
import 'widgets/home_header.dart';
import 'widgets/location_selector.dart';
import 'widgets/match_card.dart';
import 'widgets/section_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.data,
    this.onNotificationTap,
    this.onMessageTap,
    this.onLocationTap,
    this.onUpcomingViewAll,
    this.onNearbyViewAll,
    this.onMatchTap,
    this.onJoinMatch,
    this.onCreateMatch,
    this.onBottomNavTap,
    this.onRefresh,
    this.onFiltersApplied,
    this.initialFilters,
    this.onLocationSearch,
    this.onCurrentLocation,
    this.showBottomNavigation = true,
    this.showCreateFab = true,
    this.onFilterVisibilityChanged,
  });

  final HomeData? data;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onLocationTap;
  final VoidCallback? onUpcomingViewAll;
  final VoidCallback? onNearbyViewAll;
  final ValueChanged<HomeMatch>? onMatchTap;
  final Future<void> Function(HomeMatch)? onJoinMatch;
  final VoidCallback? onCreateMatch;
  final ValueChanged<int>? onBottomNavTap;
  final Future<void> Function()? onRefresh;
  final Future<void> Function(MatchFilters)? onFiltersApplied;
  final MatchFilters? initialFilters;
  final Future<List<DiscoveryLocation>> Function(String query)?
  onLocationSearch;
  final Future<DiscoveryLocation> Function()? onCurrentLocation;
  final bool showBottomNavigation;
  final bool showCreateFab;
  final ValueChanged<bool>? onFilterVisibilityChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _filterAnimationController;
  late final Animation<double> _filterFadeAnimation;
  late final Animation<Offset> _filterSlideAnimation;

  int _pageIndex = 0;
  String? _joiningMatchId;
  bool _isFilterMounted = false;
  late MatchFilters _filters;

  HomeData get _data => widget.data ?? HomePreviewData.create();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _filters = widget.initialFilters ?? MatchFilters.defaults();

    _filterAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );

    _filterFadeAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _filterSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _filterAnimationController,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextFilters = widget.initialFilters;
    if (nextFilters != null &&
        nextFilters != oldWidget.initialFilters &&
        nextFilters != _filters &&
        !_isFilterMounted) {
      _filters = nextFilters;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _filterAnimationController.dispose();
    super.dispose();
  }

  Future<void> _join(HomeMatch match) async {
    if (_joiningMatchId != null) return;

    if (match.isCurrentUserJoined || match.isOwnedByCurrentUser) {
      await _showAlreadyJoinedDialog(match);
      return;
    }

    final callback = widget.onJoinMatch;
    if (callback == null) return;

    setState(() => _joiningMatchId = match.id);
    try {
      await callback(match);
    } finally {
      if (mounted) {
        setState(() => _joiningMatchId = null);
      }
    }
  }

  Future<void> _showAlreadyJoinedDialog(HomeMatch match) async {
    final viewDetails = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Already joined',
      barrierColor: AppColors.confirmationBackdrop,
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final navigator = Navigator.of(dialogContext);

        return SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageHorizontal,
                vertical: AppSpacing.lg,
              ),
              child: AppConfirmationDialog(
                title: 'Already Joined',
                message: 'You have already joined this match.',
                cancelLabel: 'Go Back',
                confirmLabel: 'View Details',
                onCancel: () => navigator.pop(false),
                onConfirm: () => navigator.pop(true),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );

    if (viewDetails == true && mounted) {
      widget.onMatchTap?.call(match);
    }
  }

  Future<void> _openFilters() async {
    if (_isFilterMounted) return;

    FocusManager.instance.primaryFocus?.unfocus();
    widget.onLocationTap?.call();

    setState(() => _isFilterMounted = true);
    widget.onFilterVisibilityChanged?.call(true);
    await _filterAnimationController.forward(from: 0);
  }

  Future<void> _closeFilters() async {
    if (!_isFilterMounted) return;

    await _filterAnimationController.reverse();
    if (!mounted) return;

    setState(() => _isFilterMounted = false);
    widget.onFilterVisibilityChanged?.call(false);
  }

  Future<void> _applyFilters(MatchFilters filters) async {
    setState(() => _filters = filters);

    final callback = widget.onFiltersApplied;
    if (callback != null) {
      await callback(filters);
    }

    if (!mounted) return;
    await _closeFilters();
  }

  Widget _scrollView() {
    final data = _data;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverSafeArea(
          bottom: false,
          sliver: SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.lg),
                HomeHeader(
                  greeting: data.greeting,
                  displayName: data.displayName,
                  subtitle: data.subtitle,
                  notificationCount: data.unreadNotificationCount,
                  messageCount: data.unreadMessageCount,
                  onNotificationTap: widget.onNotificationTap,
                  onMessageTap: widget.onMessageTap,
                ),
                const SizedBox(height: AppSpacing.lg),
                LocationSelector(
                  location:
                      _filters.selectedLocation == MatchFilters.defaultLocation
                      ? data.location
                      : _filters.selectedLocation,
                  onTap: _openFilters,
                ),
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(
                  title: 'Upcoming Matches',
                ),
                const SizedBox(height: AppSpacing.lg),
                _UpcomingSection(
                  matches: data.upcomingMatches,
                  controller: _pageController,
                  currentPage: _pageIndex,
                  joiningMatchId: _joiningMatchId,
                  onPageChanged: (value) {
                    setState(() => _pageIndex = value);
                  },
                  onMatchTap: widget.onMatchTap,
                  onJoin: _join,
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(
                  title: 'Nearby Matches',
                  onViewAll: widget.onNearbyViewAll,
                ),
                const SizedBox(height: AppSpacing.lg),
              ]),
            ),
          ),
        ),
        if (data.nearbyMatches.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal,
            ),
            sliver: const SliverToBoxAdapter(
              child: _EmptyState(message: 'No nearby matches right now.'),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final itemIndex = index ~/ 2;

                if (index.isOdd) {
                  return const SizedBox(height: AppSpacing.md);
                }

                final match = data.nearbyMatches[itemIndex];

                return MatchCard(
                  match: match,
                  onTap: widget.onMatchTap == null
                      ? null
                      : () => widget.onMatchTap!(match),
                );
              }, childCount: data.nearbyMatches.length * 2 - 1),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildHomeBody() {
    final scrollBody = _scrollView();

    if (widget.onRefresh == null) {
      return scrollBody;
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: widget.onRefresh!,
      child: scrollBody,
    );
  }

  Widget _buildFilterOverlay() {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: _filterFadeAnimation,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeFilters,
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.62)),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _filterSlideAnimation,
              child: HomeFilterSheet(
                initialFilters: _filters,
                onApply: _applyFilters,
                onLocationSearch:
                    widget.onLocationSearch ?? (_) async => const [],
                onCurrentLocation:
                    widget.onCurrentLocation ??
                    () async => throw StateError(
                      'Current location is not available in preview mode.',
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isFilterMounted,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isFilterMounted) {
          _closeFilters();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Scaffold(
            body: _buildHomeBody(),
            floatingActionButton: _isFilterMounted || !widget.showCreateFab
                ? null
                : FloatingActionButton(
                    heroTag: 'create-match-fab',
                    onPressed: widget.onCreateMatch,
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    tooltip: 'Create match',
                    child: const Icon(Icons.add, size: 30),
                  ),
            bottomNavigationBar: widget.showBottomNavigation
                ? AppBottomNavigation(
                    currentIndex: 0,
                    onTap: _isFilterMounted ? null : widget.onBottomNavTap,
                  )
                : null,
          ),
          if (_isFilterMounted) _buildFilterOverlay(),
        ],
      ),
    );
  }
}

class _UpcomingSection extends StatelessWidget {
  const _UpcomingSection({
    required this.matches,
    required this.controller,
    required this.currentPage,
    required this.joiningMatchId,
    required this.onPageChanged,
    required this.onMatchTap,
    required this.onJoin,
  });

  final List<HomeMatch> matches;
  final PageController controller;
  final int currentPage;
  final String? joiningMatchId;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<HomeMatch>? onMatchTap;
  final Future<void> Function(HomeMatch) onJoin;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const _EmptyState(message: 'No upcoming matches right now.');
    }

    return Column(
      children: [
        SizedBox(
          height: 169,
          child: PageView.builder(
            controller: controller,
            itemCount: matches.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final match = matches[index];

              return FeaturedMatchCard(
                match: match,
                isJoining: joiningMatchId == match.id,
                onTap: onMatchTap == null ? null : () => onMatchTap!(match),
                onJoin: () => onJoin(match),
              );
            },
          ),
        ),
        if (matches.length > 1) ...[
          const SizedBox(height: 10),
          _PageIndicators(count: matches.length, activeIndex: currentPage),
        ],
      ],
    );
  }
}

class _PageIndicators extends StatelessWidget {
  const _PageIndicators({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == activeIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: active ? 14 : 7,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.textSecondary,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.65)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
