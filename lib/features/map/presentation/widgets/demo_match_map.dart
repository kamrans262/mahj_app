import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_asset_icon.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_surface_container.dart';
import '../../../home/presentation/home_date_time_formatter.dart';
import '../../domain/map_match_marker.dart';

class DemoMatchMap extends StatelessWidget {
  const DemoMatchMap({
    required this.markers,
    required this.selectedMatchId,
    required this.onMarkerTap,
    super.key,
    this.isLoading = false,
  });

  final List<MapMatchMarker> markers;
  final String? selectedMatchId;
  final ValueChanged<MapMatchMarker> onMarkerTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.subtleSurface),
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            SvgPicture.asset(AppAssets.mapDemoBackground, fit: BoxFit.cover),
            const Align(
              alignment: Alignment(0.05, 0.14),
              child: _CurrentLocationMarker(),
            ),
            for (final marker in markers)
              Align(
                alignment: Alignment(
                  marker.normalizedX * 2 - 1,
                  marker.normalizedY * 2 - 1,
                ),
                child: _MatchMarker(
                  key: ValueKey('map-marker-${marker.match.id}'),
                  marker: marker,
                  selected: marker.match.id == selectedMatchId,
                  onTap: () => onMarkerTap(marker),
                ),
              ),
            if (isLoading)
              ColoredBox(
                color: Colors.white.withValues(alpha: 0.70),
                child: const Center(child: AppLoader(color: AppColors.primary)),
              ),
          ],
        ),
      ),
    );
  }
}

class _MatchMarker extends StatelessWidget {
  const _MatchMarker({
    required this.marker,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final MapMatchMarker marker;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${marker.match.sportName} map marker',
      value: HomeDateTimeFormatter.compactDate(marker.match.startsAt),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          scale: selected ? 1.06 : 1,
          child: SizedBox(
            width: 126,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppAssetIcon(
                  assetPath: AppAssets.bottomMapIcon,
                  size: selected ? 52 : 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 4),
                AppSurfaceContainer(
                  minHeight: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        marker.match.sportName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTypography.homeMeta12.copyWith(
                          color: AppColors.heading,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        HomeDateTimeFormatter.compactDate(
                          marker.match.startsAt,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTypography.homeMeta12,
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

class _CurrentLocationMarker extends StatelessWidget {
  const _CurrentLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Current map location',
      child: ExcludeSemantics(
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              shape: BoxShape.circle,
            ),
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
