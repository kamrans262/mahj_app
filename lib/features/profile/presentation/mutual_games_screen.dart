import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_surface_container.dart';
import '../../home/domain/home_match.dart';
import '../../home/presentation/widgets/match_card.dart';
import '../data/player_repository.dart';

/// Uses Mahj's existing header, surface and reusable MatchCard.
class MutualGamesScreen extends StatefulWidget {
  const MutualGamesScreen({
    required this.playerId,
    required this.repository,
    super.key,
    this.onBack,
    this.onMatchTap,
  });

  final String playerId;
  final PlayerRepository repository;
  final VoidCallback? onBack;
  final ValueChanged<HomeMatch>? onMatchTap;

  @override
  State<MutualGamesScreen> createState() => _MutualGamesScreenState();
}

class _MutualGamesScreenState extends State<MutualGamesScreen> {
  List<HomeMatch> _games = const [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (more) {
      if (_loading || _loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final page = more ? _page + 1 : 1;
      final result = await widget.repository.fetchMutualGames(
        widget.playerId,
        page: page,
      );
      if (!mounted) return;
      setState(() {
        _page = page;
        _hasMore = result.hasMore;
        if (!more) {
          _games = result.games;
        } else {
          final ids = _games.map((game) => game.id).toSet();
          _games = [..._games, ...result.games.where((g) => ids.add(g.id))];
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException
            ? error.message
            : 'Could not load mutual games. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('mutual-games-all-screen'),
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
                title: 'Mutual Games',
                onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: AppLoader())
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _load,
                      child: ListView(
                        key: const ValueKey('mutual-games-all-list'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.pageHorizontal,
                          vertical: AppSpacing.lg,
                        ),
                        children: [
                          if (_error != null)
                            AppSurfaceContainer(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                children: [
                                  Text(_error!, style: AppTypography.body14),
                                  const SizedBox(height: AppSpacing.sm),
                                  AppButton.secondary(
                                    label: 'Retry',
                                    onPressed: _load,
                                  ),
                                ],
                              ),
                            )
                          else if (_games.isEmpty)
                            const AppSurfaceContainer(
                              padding: EdgeInsets.all(AppSpacing.lg),
                              child: Text(
                                'No mutual games yet',
                                textAlign: TextAlign.center,
                                style: AppTypography.body14,
                              ),
                            )
                          else
                            for (var i = 0; i < _games.length; i++) ...[
                              if (i > 0) const SizedBox(height: AppSpacing.lg),
                              MatchCard(
                                key: ValueKey('mutual-games-all-${_games[i].id}'),
                                match: _games[i],
                                showStatus: false,
                                onTap: widget.onMatchTap == null
                                    ? null
                                    : () => widget.onMatchTap!(_games[i]),
                              ),
                            ],
                          if (_hasMore && _error == null) ...[
                            const SizedBox(height: AppSpacing.lg),
                            AppButton.secondary(
                              key: const ValueKey('mutual-games-load-more'),
                              label: 'Load More',
                              isLoading: _loadingMore,
                              onPressed: _loadingMore ? null : () => _load(more: true),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
