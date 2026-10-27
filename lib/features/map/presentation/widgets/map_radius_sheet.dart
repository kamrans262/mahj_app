import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../home/domain/match_filters.dart';
import '../../../home/presentation/widgets/radius_slider.dart';

/// Compact version of Mahj's existing Filters sheet for changing map radius.
/// A draft is kept locally until the user explicitly applies it.
class MapRadiusSheet extends StatefulWidget {
  const MapRadiusSheet({
    required this.initialRadius,
    super.key,
  });

  final double initialRadius;

  @override
  State<MapRadiusSheet> createState() => _MapRadiusSheetState();
}

class _MapRadiusSheetState extends State<MapRadiusSheet> {
  late double _draftRadius;

  @override
  void initState() {
    super.initState();
    _draftRadius = widget.initialRadius
        .round()
        .clamp(MatchFilters.minRadiusMiles, MatchFilters.maxRadiusMiles)
        .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final compactActions = MediaQuery.textScalerOf(context).scale(1) > 1.35 ||
        mediaQuery.size.width < 340;

    final cancelButton = AppButton.secondary(
      key: const ValueKey('map-radius-cancel'),
      label: 'Cancel',
      onPressed: () => Navigator.of(context).pop(),
    );
    final applyButton = AppButton.primary(
      key: const ValueKey('map-radius-apply'),
      label: 'Apply Radius',
      onPressed: () => Navigator.of(context).pop(_draftRadius),
    );

    return Material(
      key: const ValueKey('map-radius-sheet'),
      color: AppColors.background,
      elevation: 12,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheetTop),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.72),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.lg,
            AppSpacing.pageHorizontal,
            AppSpacing.lg + mediaQuery.padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select Radius',
                textAlign: TextAlign.center,
                style: AppTypography.homeGreeting,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Choose how far to search for matches',
                textAlign: TextAlign.center,
                style: AppTypography.homeMeta14,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                '${_draftRadius.round()} ${_draftRadius.round() == 1 ? 'mile' : 'miles'}',
                key: const ValueKey('map-radius-selected-value'),
                textAlign: TextAlign.center,
                style: AppTypography.homeMatchTitle18.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              RadiusSlider(
                value: _draftRadius,
                onChanged: (value) {
                  setState(() => _draftRadius = value.roundToDouble());
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (compactActions) ...[
                cancelButton,
                const SizedBox(height: AppSpacing.sm),
                applyButton,
              ] else
                Row(
                  children: [
                    Expanded(child: cancelButton),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: applyButton),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
