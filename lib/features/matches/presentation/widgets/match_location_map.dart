import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../core/widgets/app_asset_icon.dart';

class MatchLocationMap extends StatelessWidget {
  const MatchLocationMap({
    super.key,
    this.markerAlignment = const Alignment(0.22, -0.12),
  });

  final Alignment markerAlignment;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Match location map',
      child: AspectRatio(
        aspectRatio: 2.15,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: AppColors.subtleSurface),
            child: Stack(
              fit: StackFit.expand,
              children: [
                SvgPicture.asset(
                  AppAssets.mapDemoBackground,
                  fit: BoxFit.cover,
                ),
                Align(
                  alignment: markerAlignment,
                  child: const AppAssetIcon(
                    key: ValueKey('match-details-map-marker'),
                    assetPath: AppAssets.mapMatchMarkerIcon,
                    size: 44,
                    color: AppColors.textSecondary,
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
