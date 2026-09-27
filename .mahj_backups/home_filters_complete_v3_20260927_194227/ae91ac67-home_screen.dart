import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../data/home_preview_data.dart';
import '../domain/home_data.dart';
import '../domain/home_match.dart';
import 'widgets/app_bottom_navigation.dart';
import 'widgets/featured_match_card.dart';
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

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PageController _pageController;
  int _pageIndex = 0;
  String? _joiningMatchId;

  HomeData get _data => widget.data ?? HomePreviewData.create();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _join(HomeMatch match) async {
    final callback = widget.onJoinMatch;
    if (callback == null || _joiningMatchId != null) return;

    setState(() => _joiningMatchId = match.id);
    try {
      await callback(match);
    } finally {
      if (mounted) {
        setState(() => _joiningMatchId = null);
      }
    }
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
                  location: data.location,
                  onTap: widget.onLocationTap,
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(
                  title: 'Upcoming Matches',
                  onViewAll: widget.onUpcomingViewAll,
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
            sliver: SliverToBoxAdapter(
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

  @override
  Widget build(BuildContext context) {
    final body = _scrollView();

    return Scaffold(
      body: widget.onRefresh == null
          ? body
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: widget.onRefresh!,
              child: body,
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'create-match-fab',
        onPressed: widget.onCreateMatch,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Create match',
        child: const Icon(Icons.add, size: 30),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: AppBottomNavigation(
          currentIndex: 0,
          onTap: widget.onBottomNavTap,
        ),
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
      return const _EmptyState(message: 'No upcoming matches yet.');
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
