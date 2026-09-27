import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_icon_action_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/nearby_matches_preview_data.dart';
import '../domain/home_match.dart';
import 'widgets/location_selection_dialog.dart';
import 'widgets/location_selector.dart';
import 'widgets/match_card.dart';

enum NearbyMatchesSortOption { distance }

class AllNearbyMatchesScreen extends StatefulWidget {
  const AllNearbyMatchesScreen({
    super.key,
    this.matches,
    this.initialLocation = '1001, New York, NY',
    this.onBack,
    this.onLocationChanged,
    this.onSearch,
    this.onSortChanged,
    this.onMatchTap,
    this.onCreateMatch,
    this.onRefresh,
    this.onLoadMore,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<HomeMatch>? matches;
  final String initialLocation;
  final VoidCallback? onBack;
  final ValueChanged<String>? onLocationChanged;
  final Future<void> Function(String query)? onSearch;
  final ValueChanged<NearbyMatchesSortOption>? onSortChanged;
  final ValueChanged<HomeMatch>? onMatchTap;
  final VoidCallback? onCreateMatch;
  final Future<void> Function()? onRefresh;
  final Future<void> Function()? onLoadMore;
  final bool isLoading;
  final String? errorMessage;

  @override
  State<AllNearbyMatchesScreen> createState() => _AllNearbyMatchesScreenState();
}

class _AllNearbyMatchesScreenState extends State<AllNearbyMatchesScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _scrollController = ScrollController();

  late String _selectedLocation;
  NearbyMatchesSortOption _sortOption = NearbyMatchesSortOption.distance;
  String _submittedQuery = '';
  bool _loadMoreRequested = false;
  bool _searching = false;

  List<HomeMatch> get _sourceMatches =>
      widget.matches ?? NearbyMatchesPreviewData.create();

  List<HomeMatch> get _visibleMatches {
    final query = _submittedQuery.trim().toLowerCase();
    if (query.isEmpty) return _sourceMatches;

    return _sourceMatches
        .where((match) {
          return match.sportName.toLowerCase().contains(query) ||
              match.location.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _scrollController.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(covariant AllNearbyMatchesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matches?.length != widget.matches?.length) {
      _loadMoreRequested = false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    final callback = widget.onLoadMore;
    if (callback == null ||
        _loadMoreRequested ||
        !_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    if (position.extentAfter > 320) return;

    _loadMoreRequested = true;
    callback().whenComplete(() {
      if (mounted) {
        _loadMoreRequested = false;
      }
    });
  }

  Future<void> _selectLocation() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final selected = await showLocationSelectionDialog(
      context: context,
      selectedLocation: _selectedLocation,
    );

    if (!mounted || selected == null) return;

    setState(() => _selectedLocation = selected);
    widget.onLocationChanged?.call(selected);
  }

  Future<void> _submitSearch() async {
    if (_searching) return;

    final query = _searchController.text.trim();
    setState(() {
      _submittedQuery = query;
      _searching = true;
    });

    FocusManager.instance.primaryFocus?.unfocus();

    try {
      final callback = widget.onSearch;
      if (callback != null) {
        await callback(query);
      }
    } finally {
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  void _setSort(NearbyMatchesSortOption value) {
    if (_sortOption == value) return;

    setState(() => _sortOption = value);
    widget.onSortChanged?.call(value);
  }

  String _countLabel(int count) {
    return count == 1 ? '1 match found' : '$count matches found';
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      child: SizedBox(
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: AppBackButton(
                onPressed:
                    widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
            ),
            const IgnorePointer(
              child: Text(
                'Create Match',
                textAlign: TextAlign.center,
                style: AppTypography.homeGreeting,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppTextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            hintText: 'Search match or venues',
            leadingIcon: Icons.search,
            textInputAction: TextInputAction.search,
            enabled: !_searching,
            onFieldSubmitted: (_) => _submitSearch(),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppIconActionButton(
          onPressed: _searching ? null : _submitSearch,
          assetPath: AppAssets.resetSendIcon,
          fallbackIcon: Icons.near_me_outlined,
          isLoading: _searching,
          semanticLabel: 'Search nearby matches',
        ),
      ],
    );
  }

  Widget _buildResultsHeader(int count) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nearby Matches',
                style: AppTypography.homeSectionHeading,
              ),
              const SizedBox(height: 5),
              Text(_countLabel(count), style: AppTypography.homeMeta12),
            ],
          ),
        ),
        const SizedBox(width: 12),
        PopupMenuButton<NearbyMatchesSortOption>(
          initialValue: _sortOption,
          onSelected: _setSort,
          tooltip: 'Sort nearby matches',
          color: AppColors.background,
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: NearbyMatchesSortOption.distance,
              child: Text('Distance'),
            ),
          ],
          child: Semantics(
            button: true,
            label: 'Sort nearby matches by distance',
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Sort: Distance', style: AppTypography.homeMeta12),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStateContent(List<HomeMatch> matches) {
    if (widget.isLoading && matches.isEmpty) {
      return const _NearbyStateCard(message: 'Loading nearby matches…');
    }

    final error = widget.errorMessage;
    if (error != null && error.isNotEmpty && matches.isEmpty) {
      return _NearbyStateCard(
        message: error,
        actionLabel: widget.onRefresh == null ? null : 'Retry',
        onAction: widget.onRefresh,
      );
    }

    if (matches.isEmpty) {
      return const _NearbyStateCard(message: 'No nearby matches found');
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _visibleMatches;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    final scrollView = CustomScrollView(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              LocationSelector(
                location: _selectedLocation,
                onTap: _selectLocation,
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSearchRow(),
              const SizedBox(height: AppSpacing.lg),
              _buildResultsHeader(matches.length),
              const SizedBox(height: AppSpacing.lg),
              if (matches.isEmpty) _buildStateContent(matches),
            ]),
          ),
        ),
        if (matches.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index.isOdd) {
                  return const SizedBox(height: AppSpacing.md);
                }

                final itemIndex = index ~/ 2;
                final match = matches[itemIndex];

                return MatchCard(
                  match: match,
                  onTap: widget.onMatchTap == null
                      ? null
                      : () => widget.onMatchTap!(match),
                );
              }, childCount: matches.length * 2 - 1),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
      ],
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: widget.onRefresh == null
                  ? scrollView
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: widget.onRefresh!,
                      child: scrollView,
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: keyboardOpen
          ? null
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                12,
                AppSpacing.pageHorizontal,
                16,
              ),
              child: AppButton.primary(
                label: 'Create Match',
                onPressed: widget.onCreateMatch,
                isEnabled: widget.onCreateMatch != null,
              ),
            ),
    );
  }
}

class _NearbyStateCard extends StatelessWidget {
  const _NearbyStateCard({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.nearbyMatchCardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.subtleBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.subtleShadow,
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.homeMeta14,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton.secondary(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}
