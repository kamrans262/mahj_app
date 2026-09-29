import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_surface_container.dart';
import '../../../home/presentation/home_date_time_formatter.dart';
import '../../../home/presentation/widgets/match_card.dart';
import '../../../home/presentation/widgets/match_status_badge.dart';
import '../../domain/my_matches_data.dart';
import 'match_preview_media.dart';

class MyMatchPreviewCard extends StatelessWidget {
  const MyMatchPreviewCard({required this.item, super.key, this.onTap});

  final MyMatchesItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceContainer(
      onTap: onTap,
      semanticsLabel: '${item.match.location} match details',
      padding: EdgeInsets.zero,
      minHeight: 0,
      borderRadius: AppRadius.control,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final shouldStack = constraints.maxWidth < 310 || textScale > 1.5;

          if (shouldStack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 140,
                  child: MatchPreviewMedia(
                    hasLocationPreview: item.hasLocationPreview,
                    markerNormalizedX: item.markerNormalizedX,
                    markerNormalizedY: item.markerNormalizedY,
                    sportImageAsset: item.sportImageAsset,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: _MatchInformation(item: item),
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 104,
                height: 104,
                child: MatchPreviewMedia(
                  hasLocationPreview: item.hasLocationPreview,
                  markerNormalizedX: item.markerNormalizedX,
                  markerNormalizedY: item.markerNormalizedY,
                  sportImageAsset: item.sportImageAsset,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: _MatchInformation(item: item),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MatchInformation extends StatelessWidget {
  const _MatchInformation({required this.item});

  final MyMatchesItem item;

  @override
  Widget build(BuildContext context) {
    final match = item.match;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          match.location,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.homeMatchTitle16,
        ),
        const SizedBox(height: AppSpacing.sm),
        MatchMetadataItem(
          icon: Icons.calendar_today_outlined,
          iconColor: AppColors.textSecondary,
          text: HomeDateTimeFormatter.compactDate(match.startsAt),
        ),
        const SizedBox(height: AppSpacing.micro),
        MatchMetadataItem(
          icon: Icons.access_time,
          text: HomeDateTimeFormatter.time(match.startsAt),
        ),
        const SizedBox(height: AppSpacing.micro),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                '${match.currentPlayers}/${match.maxPlayers} Players',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.homeMeta12,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            MatchStatusBadge(status: match.status),
          ],
        ),
      ],
    );
  }
}
