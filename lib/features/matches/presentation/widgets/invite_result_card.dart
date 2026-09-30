import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_surface_container.dart';
import '../../../home/presentation/home_date_time_formatter.dart';
import '../../../home/presentation/widgets/match_card.dart';
import '../../domain/invite_player_result.dart';
import 'match_preview_media.dart';

class InviteResultCard extends StatelessWidget {
  const InviteResultCard({
    required this.result,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final InvitePlayerResult result;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final shouldStack = screenWidth < 350 || textScale > 1.45;

    return Semantics(
      selected: isSelected,
      label: '${result.searchText}, ${result.title}',
      child: AppSurfaceContainer(
        onTap: onTap,
        semanticsLabel: isSelected
            ? 'Deselect ${result.searchText}'
            : 'Select ${result.searchText}',
        padding: EdgeInsets.zero,
        minHeight: 0,
        borderRadius: AppRadius.control,
        borderColor: isSelected ? AppColors.primary : AppColors.controlBorder,
        child: shouldStack ? _stackedContent() : _rowContent(),
      ),
    );
  }

  Widget _stackedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 124,
          child: MatchPreviewMedia(
            hasLocationPreview: result.hasLocationPreview,
            latitude: result.latitude,
            longitude: result.longitude,
            markerNormalizedX: result.markerNormalizedX,
            markerNormalizedY: result.markerNormalizedY,
            sportImageAsset: result.sportImageAsset,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: _ResultInformation(result: result, isSelected: isSelected),
        ),
      ],
    );
  }

  Widget _rowContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          height: 108,
          child: MatchPreviewMedia(
            hasLocationPreview: result.hasLocationPreview,
            latitude: result.latitude,
            longitude: result.longitude,
            markerNormalizedX: result.markerNormalizedX,
            markerNormalizedY: result.markerNormalizedY,
            sportImageAsset: result.sportImageAsset,
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
            child: _ResultInformation(result: result, isSelected: isSelected),
          ),
        ),
      ],
    );
  }
}

class _ResultInformation extends StatelessWidget {
  const _ResultInformation({required this.result, required this.isSelected});

  final InvitePlayerResult result;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                result.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.homeMatchTitle16,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: AppSpacing.xs),
              const _SelectedIndicator(),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        MatchMetadataItem(
          icon: Icons.calendar_today_outlined,
          iconColor: AppColors.textSecondary,
          text: HomeDateTimeFormatter.compactDate(result.startsAt),
        ),
        const SizedBox(height: AppSpacing.micro),
        MatchMetadataItem(
          icon: Icons.access_time,
          text: HomeDateTimeFormatter.time(result.startsAt),
        ),
        const SizedBox(height: AppSpacing.micro),
        Text(
          '${result.currentPlayers}/${result.maxPlayers} Players',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.homeMeta12,
        ),
      ],
    );
  }
}

class _SelectedIndicator extends StatelessWidget {
  const _SelectedIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check_rounded, size: 15, color: Colors.white),
    );
  }
}
