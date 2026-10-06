import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_surface_container.dart';
import '../../home/domain/home_match.dart';
import '../../home/presentation/widgets/match_card.dart';
import '../../matches/data/match_repository.dart';
import '../data/player_repository.dart';
import '../domain/favorite_player.dart';

enum FavoritesTab { byMatch, byPlayer }

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({
    required this.matchRepository,
    required this.playerRepository,
    required this.onMatchTap,
    required this.onPlayerTap,
    super.key,
    this.onBack,
  });

  final MatchRepository matchRepository;
  final PlayerRepository playerRepository;
  final Future<void> Function(HomeMatch match) onMatchTap;
  final Future<void> Function(FavoritePlayer player) onPlayerTap;
  final VoidCallback? onBack;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  FavoritesTab _selectedTab = FavoritesTab.byMatch;
  List<HomeMatch> _matches = const <HomeMatch>[];
  List<FavoritePlayer> _players = const <FavoritePlayer>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final matches = await widget.matchRepository.listFavorites();
      final players = await widget.playerRepository.listFavorites();
      if (!mounted) return;

      setState(() {
        _matches = matches;
        _players = players;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load favorites. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openMatch(HomeMatch match) async {
    await widget.onMatchTap(match);
    if (mounted) await _load();
  }

  Future<void> _openPlayer(FavoritePlayer player) async {
    await widget.onPlayerTap(player);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.lg,
                AppSpacing.pageHorizontal,
                0,
              ),
              child: AppCenteredPageHeader(
                title: 'Favorites',
                onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.xxl,
                AppSpacing.pageHorizontal,
                0,
              ),
              child: _FavoritesTabs(
                selectedTab: _selectedTab,
                onSelected: (tab) => setState(() => _selectedTab = tab),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final isEmpty = _selectedTab == FavoritesTab.byMatch
        ? _matches.isEmpty
        : _players.isEmpty;

    if (_loading && isEmpty) {
      return const Center(child: AppLoader());
    }

    if (_error != null && isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
          children: [
            const SizedBox(height: 60),
            AppSurfaceContainer(
              minHeight: 120,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: AppTypography.body14,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: _load,
                    child: Text('Retry', style: AppTypography.action14),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return _selectedTab == FavoritesTab.byMatch
        ? _buildMatchFavorites()
        : _buildPlayerFavorites();
  }

  Widget _buildMatchFavorites() {
    if (_matches.isEmpty) {
      return _EmptyFavorites(
        onRefresh: _load,
        icon: Icons.star_border_rounded,
        title: 'No favorite matches yet',
        message: 'Tap the star on Match Details to save a match here.',
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          0,
          AppSpacing.pageHorizontal,
          AppSpacing.xxl,
        ),
        itemCount: _matches.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final match = _matches[index];
          return MatchCard(
            key: ValueKey('favorite-match-${match.id}'),
            match: match,
            onTap: () => _openMatch(match),
          );
        },
      ),
    );
  }

  Widget _buildPlayerFavorites() {
    if (_players.isEmpty) {
      return _EmptyFavorites(
        onRefresh: _load,
        icon: Icons.person_outline_rounded,
        title: 'No favorite players yet',
        message: 'Add a player to favorites from their Player Profile.',
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          0,
          AppSpacing.pageHorizontal,
          AppSpacing.xxl,
        ),
        itemCount: _players.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final player = _players[index];
          return _FavoritePlayerCard(
            player: player,
            onTap: () => _openPlayer(player),
          );
        },
      ),
    );
  }
}

class _FavoritesTabs extends StatelessWidget {
  const _FavoritesTabs({
    required this.selectedTab,
    required this.onSelected,
  });

  final FavoritesTab selectedTab;
  final ValueChanged<FavoritesTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FavoriteTabButton(
            label: 'By Match',
            selected: selectedTab == FavoritesTab.byMatch,
            onTap: () => onSelected(FavoritesTab.byMatch),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _FavoriteTabButton(
            label: 'By Player',
            selected: selectedTab == FavoritesTab.byPlayer,
            onTap: () => onSelected(FavoritesTab.byPlayer),
          ),
        ),
      ],
    );
  }
}

class _FavoriteTabButton extends StatelessWidget {
  const _FavoriteTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceContainer(
      onTap: onTap,
      minHeight: 42,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      backgroundColor: selected ? AppColors.primary : AppColors.subtleSurface,
      borderColor: selected ? AppColors.primary : AppColors.controlBorder,
      child: Center(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.homeMeta14.copyWith(
            color: selected ? Colors.white : AppColors.heading,
          ),
        ),
      ),
    );
  }
}

class _FavoritePlayerCard extends StatelessWidget {
  const _FavoritePlayerCard({
    required this.player,
    required this.onTap,
  });

  final FavoritePlayer player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceContainer(
      key: ValueKey('favorite-player-${player.id}'),
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          AppAvatar(
            fallbackAsset: AppAssets.bottomProfileIcon,
            imageUrl: player.avatarUrl,
            size: 44,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.homeMatchTitle16,
                ),
                const SizedBox(height: AppSpacing.micro),
                Text(
                  player.secondaryLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.homeMeta12,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites({
    required this.onRefresh,
    required this.icon,
    required this.title,
    required this.message,
  });

  final Future<void> Function() onRefresh;
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        children: [
          const SizedBox(height: 60),
          AppSurfaceContainer(
            minHeight: 150,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: AppColors.primary),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  style: AppTypography.title18,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  style: AppTypography.homeMeta14,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
