import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_surface_container.dart';
import '../../home/presentation/widgets/home_header.dart';
import '../data/my_matches_preview_data.dart';
import '../domain/my_matches_data.dart';
import 'widgets/my_match_preview_card.dart';

class MyMatchesScreen extends StatefulWidget {
  const MyMatchesScreen({
    super.key,
    this.data,
    this.initialTab = MyMatchesTab.upcoming,
    this.loadingTabs = const <MyMatchesTab>{},
    this.errorMessages = const <MyMatchesTab, String>{},
    this.onNotificationTap,
    this.onMessageTap,
    this.onTabChanged,
    this.onMatchTap,
    this.onInvitationTap,
    this.onRefresh,
    this.onLoadMore,
  });

  final MyMatchesData? data;
  final MyMatchesTab initialTab;
  final Set<MyMatchesTab> loadingTabs;
  final Map<MyMatchesTab, String> errorMessages;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMessageTap;
  final ValueChanged<MyMatchesTab>? onTabChanged;
  final void Function(MyMatchesItem item, MyMatchesTab tab)? onMatchTap;
  final ValueChanged<MyMatchesItem>? onInvitationTap;
  final Future<void> Function(MyMatchesTab tab)? onRefresh;
  final Future<void> Function(MyMatchesTab tab)? onLoadMore;

  @override
  State<MyMatchesScreen> createState() => _MyMatchesScreenState();
}

class _MyMatchesScreenState extends State<MyMatchesScreen> {
  late MyMatchesTab _selectedTab;
  final ScrollController _scrollController = ScrollController();
  MyMatchesTab? _loadingMoreTab;

  MyMatchesData get _data => widget.data ?? MyMatchesPreviewData.create();

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MyMatchesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _selectedTab = widget.initialTab;
    }
  }

  void _selectTab(MyMatchesTab tab) {
    if (_selectedTab == tab) return;
    setState(() => _selectedTab = tab);
    widget.onTabChanged?.call(tab);
  }

  String get _emptyMessage {
    return switch (_selectedTab) {
      MyMatchesTab.upcoming => 'No upcoming matches',
      MyMatchesTab.createdByMe => "You haven't created any matches yet",
      MyMatchesTab.invites => 'No match invitations',
      MyMatchesTab.completed => 'No completed matches',
      MyMatchesTab.cancelled => 'No cancelled matches',
    };
  }

  Future<void> _refresh() async {
    final callback = widget.onRefresh;
    if (callback != null) {
      await callback(_selectedTab);
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.maxScrollExtent - position.pixels <= 180) {
      _requestMore();
    }
  }

  Future<void> _requestMore() async {
    final callback = widget.onLoadMore;
    final tab = _selectedTab;
    if (callback == null ||
        _loadingMoreTab != null ||
        !_data.hasMoreForTab(tab)) {
      return;
    }

    setState(() => _loadingMoreTab = tab);
    try {
      await callback(tab);
    } finally {
      if (mounted && _loadingMoreTab == tab) {
        setState(() => _loadingMoreTab = null);
      }
    }
  }

  Widget _buildBody() {
    final data = _data;
    final items = data.forTab(_selectedTab);
    final isLoading = widget.loadingTabs.contains(_selectedTab);
    final errorMessage = widget.errorMessages[_selectedTab];

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverSafeArea(
          bottom: false,
          sliver: SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal,
              AppSpacing.lg,
              AppSpacing.pageHorizontal,
              0,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _MyMatchesHeader(
                  notificationCount: data.unreadNotificationCount,
                  messageCount: data.unreadMessageCount,
                  onNotificationTap: widget.onNotificationTap,
                  onMessageTap: widget.onMessageTap,
                ),
                const SizedBox(height: AppSpacing.xxl),
                _MyMatchesTabs(
                  selectedTab: _selectedTab,
                  onSelected: _selectTab,
                ),
                const SizedBox(height: AppSpacing.lg),
              ]),
            ),
          ),
        ),
        if (isLoading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: AppLoader()),
          )
        else if (errorMessage != null)
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal,
            ),
            sliver: SliverToBoxAdapter(
              child: _StateMessage(
                message: errorMessage,
                actionLabel: widget.onRefresh == null ? null : 'Retry',
                onAction: widget.onRefresh == null ? null : _refresh,
              ),
            ),
          )
        else if (items.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal,
            ),
            sliver: SliverToBoxAdapter(
              child: _StateMessage(message: _emptyMessage),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index.isOdd) {
                  return const SizedBox(height: AppSpacing.lg);
                }

                final item = items[index ~/ 2];
                final activeTab = _selectedTab;
                final hasTapHandler = activeTab == MyMatchesTab.invites
                    ? widget.onInvitationTap != null ||
                          widget.onMatchTap != null
                    : widget.onMatchTap != null;

                return MyMatchPreviewCard(
                  key: ValueKey('my-match-card-${item.match.id}'),
                  item: item,
                  onTap: !hasTapHandler
                      ? null
                      : () {
                          if (activeTab == MyMatchesTab.invites &&
                              widget.onInvitationTap != null) {
                            widget.onInvitationTap!(item);
                            return;
                          }
                          widget.onMatchTap?.call(item, activeTab);
                        },
                );
              }, childCount: items.length * 2 - 1),
            ),
          ),
        if (_loadingMoreTab == _selectedTab)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: AppLoader()),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    if (widget.onRefresh == null) return body;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refresh,
      child: body,
    );
  }
}

class _MyMatchesHeader extends StatelessWidget {
  const _MyMatchesHeader({
    required this.notificationCount,
    required this.messageCount,
    this.onNotificationTap,
    this.onMessageTap,
  });

  final int notificationCount;
  final int messageCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMessageTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'My Matches',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.homeGreeting,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        HeaderActionButton(
          key: const ValueKey('my-matches-header-notifications'),
          semanticsLabel: 'Notifications',
          assetPath: AppAssets.homeBellIcon,
          fallbackIcon: Icons.notifications_none,
          unreadCount: notificationCount,
          onTap: onNotificationTap,
        ),
        const SizedBox(width: AppSpacing.md),
        HeaderActionButton(
          key: const ValueKey('my-matches-header-messages'),
          semanticsLabel: 'Messages',
          assetPath: AppAssets.homeMessageIcon,
          fallbackIcon: Icons.chat_bubble_outline,
          unreadCount: messageCount,
          onTap: onMessageTap,
        ),
      ],
    );
  }
}

class _MyMatchesTabs extends StatelessWidget {
  const _MyMatchesTabs({required this.selectedTab, required this.onSelected});

  final MyMatchesTab selectedTab;
  final ValueChanged<MyMatchesTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: MyMatchesTab.values.map((tab) {
        return _MyMatchesTabButton(
          tab: tab,
          selected: tab == selectedTab,
          onTap: () => onSelected(tab),
        );
      }).toList(growable: false),
    );
  }

}

class _MyMatchesTabButton extends StatelessWidget {
  const _MyMatchesTabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final MyMatchesTab tab;
  final bool selected;
  final VoidCallback onTap;

  String get _label {
    return switch (tab) {
      MyMatchesTab.upcoming => 'Upcoming',
      MyMatchesTab.createdByMe => 'Created by Me',
      MyMatchesTab.invites => 'Invites',
      MyMatchesTab.completed => 'Completed',
      MyMatchesTab.cancelled => 'Cancelled',
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppSurfaceContainer(
      key: ValueKey('my-matches-tab-${tab.name}'),
      onTap: onTap,
      semanticsLabel: 'Show $_label matches',
      minHeight: 42,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      backgroundColor: selected ? AppColors.primary : AppColors.subtleSurface,
      borderColor: selected ? AppColors.primary : AppColors.controlBorder,
      child: Center(
        child: Text(
          _label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTypography.homeMeta14.copyWith(
            color: selected ? Colors.white : AppColors.heading,
          ),
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceContainer(
      minHeight: 96,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body14,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () async {
                await onAction!();
              },
              child: Text(actionLabel!, style: AppTypography.action14),
            ),
          ],
        ],
      ),
    );
  }
}
