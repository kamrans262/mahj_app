import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_asset_icon.dart';
import '../../domain/home_match.dart';
import '../home_date_time_formatter.dart';
import 'match_status_badge.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({required this.match, super.key, this.onTap});

  final HomeMatch match;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${match.sportName} match, ${match.location}',
      child: Material(
        color: AppColors.nearbyMatchCardSurface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 108),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.65),
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SportIcon(match: match),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            match.sportName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.homeMatchTitle16,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            match.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.homeMeta12,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    MatchStatusBadge(status: match.status),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.divider.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final children = [
                      MatchMetadataItem(
                        icon: Icons.calendar_today,
                        text: HomeDateTimeFormatter.compactDate(match.startsAt),
                      ),
                      MatchMetadataItem(
                        icon: Icons.access_time,
                        text: HomeDateTimeFormatter.time(match.startsAt),
                      ),
                      MatchMetadataItem(
                        text:
                            '${match.currentPlayers}/${match.maxPlayers} Players',
                      ),
                    ];

                    if (constraints.maxWidth < 315) {
                      return Wrap(
                        spacing: 16,
                        runSpacing: 10,
                        children: children,
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: children[0]),
                        const SizedBox(width: 8),
                        Flexible(child: children[1]),
                        const SizedBox(width: 8),
                        Flexible(child: children[2]),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MatchMetadataItem extends StatelessWidget {
  const MatchMetadataItem({required this.text, super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: const Color(0xFF6E8668)),
          const SizedBox(width: 7),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.homeMeta12,
          ),
        ),
      ],
    );
  }
}

class _SportIcon extends StatelessWidget {
  const _SportIcon({required this.match});

  final HomeMatch match;

  @override
  Widget build(BuildContext context) {
    if (match.sportIconAsset.isNotEmpty) {
      return AppAssetIcon(assetPath: match.sportIconAsset, size: 24);
    }

    return const Icon(Icons.sports_soccer, size: 24, color: AppColors.heading);
  }
}
