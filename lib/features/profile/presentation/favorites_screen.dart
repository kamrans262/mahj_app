import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_surface_container.dart';
import '../../home/domain/home_match.dart';
import '../../home/presentation/widgets/match_card.dart';
import '../../matches/data/match_repository.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({
    required this.repository,
    required this.onMatchTap,
    super.key,
    this.onBack,
  });

  final MatchRepository repository;
  final Future<void> Function(HomeMatch match) onMatchTap;
  final VoidCallback? onBack;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<HomeMatch> _matches = const <HomeMatch>[];
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
      final matches = await widget.repository.listFavorites();
      if (!mounted) return;
      setState(() => _matches = matches);
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
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _matches.isEmpty) {
      return const Center(child: AppLoader());
    }

    if (_error != null && _matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
          child: AppSurfaceContainer(
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
        ),
      );
    }

    if (_matches.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
          children: [
            const SizedBox(height: 80),
            AppSurfaceContainer(
              minHeight: 150,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.star_border_rounded,
                    size: 40,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No favorite matches yet',
                    style: AppTypography.title18,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Tap the star on Match Details to save a match here.',
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

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          25,
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
}
