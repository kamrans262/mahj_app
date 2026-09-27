import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_asset_icon.dart';
import '../../domain/home_match.dart';
import '../home_date_time_formatter.dart';

class FeaturedMatchCard extends StatelessWidget {
  const FeaturedMatchCard({
    required this.match,
    super.key,
    this.onTap,
    this.onJoin,
    this.isJoining = false,
  });

  final HomeMatch match;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final bool isJoining;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${match.sportName} match at ${match.location}',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 169),
            child: Stack(
              children: [
                Positioned.fill(child: _Background(match: match)),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SportIcon(match: match, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  match.sportName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.homeMatchTitle18,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  HomeDateTimeFormatter.featuredSchedule(
                                    match.startsAt,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.homeMeta14,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  '${match.currentPlayers}/${match.maxPlayers} ',
                              style: AppTypography.homeMatchTitle18.copyWith(
                                fontSize: 16,
                              ),
                            ),
                            TextSpan(
                              text: 'Players',
                              style: AppTypography.homeMeta14,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              match.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.homeMeta14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 36,
                            child: FilledButton(
                              onPressed:
                                  match.isJoinable &&
                                      !match.isFull &&
                                      !isJoining
                                  ? onJoin
                                  : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor: AppColors.disabled,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: isJoining
                                  ? const SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Join Match',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background({required this.match});

  final HomeMatch match;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFF7F0),
            AppColors.primary.withValues(alpha: 0.12),
          ],
        ),
      ),
    );

    if (match.bannerAsset.isEmpty) return fallback;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          match.bannerAsset,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, _, _) => fallback,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white.withValues(alpha: 0.88),
                Colors.white.withValues(alpha: 0.40),
                Colors.transparent,
              ],
              stops: const [0, 0.52, 1],
            ),
          ),
        ),
      ],
    );
  }
}

class _SportIcon extends StatelessWidget {
  const _SportIcon({required this.match, required this.size});

  final HomeMatch match;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (match.sportIconAsset.isNotEmpty) {
      return AppAssetIcon(assetPath: match.sportIconAsset, size: size);
    }

    final sport = match.sportName.toLowerCase();
    final icon = sport.contains('basket')
        ? Icons.sports_basketball
        : sport.contains('tennis')
        ? Icons.sports_tennis
        : Icons.sports_soccer;

    return Icon(icon, size: size, color: AppColors.heading);
  }
}
