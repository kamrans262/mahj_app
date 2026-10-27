import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/match_filters.dart';

/// The shared Mahj 1–50 mile slider used by Home filters and Map radius.
class RadiusSlider extends StatelessWidget {
  const RadiusSlider({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Search radius',
      value: '${value.round()} miles',
      child: Column(
        children: [
          SizedBox(
            height: 28,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.filterSliderInactive,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withValues(alpha: 0.08),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                tickMarkShape: SliderTickMarkShape.noTickMark,
              ),
              child: Slider(
                key: const ValueKey('mahj-radius-slider'),
                min: MatchFilters.minRadiusMiles,
                max: MatchFilters.maxRadiusMiles,
                divisions: (MatchFilters.maxRadiusMiles -
                        MatchFilters.minRadiusMiles)
                    .round(),
                value: value.clamp(
                  MatchFilters.minRadiusMiles,
                  MatchFilters.maxRadiusMiles,
                ),
                onChanged: onChanged,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 mile', style: AppTypography.homeMeta14),
              Text('50 miles', style: AppTypography.homeMeta14),
            ],
          ),
        ],
      ),
    );
  }
}
