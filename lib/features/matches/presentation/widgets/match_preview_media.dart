import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_asset_icon.dart';

class MatchPreviewMedia extends StatelessWidget {
  const MatchPreviewMedia({
    required this.hasLocationPreview,
    required this.sportImageAsset,
    super.key,
    this.markerNormalizedX,
    this.markerNormalizedY,
  });

  final bool hasLocationPreview;
  final String sportImageAsset;
  final double? markerNormalizedX;
  final double? markerNormalizedY;

  @override
  Widget build(BuildContext context) {
    if (!hasLocationPreview) {
      return _SportImage(assetPath: sportImageAsset);
    }

    final normalizedX = _normalized(markerNormalizedX ?? 0.5);
    final normalizedY = _normalized(markerNormalizedY ?? 0.5);

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        SvgPicture.asset(AppAssets.mapDemoBackground, fit: BoxFit.cover),
        Align(
          alignment: Alignment(normalizedX * 2 - 1, normalizedY * 2 - 1),
          child: const AppAssetIcon(
            assetPath: AppAssets.mapMatchMarkerIcon,
            size: 48,
          ),
        ),
      ],
    );
  }

  double _normalized(double value) {
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }
}

class _SportImage extends StatelessWidget {
  const _SportImage({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        return ColoredBox(
          color: AppColors.subtleSurface,
          child: Center(
            child: AppAssetIcon(
              assetPath: AppAssets.homeFootballIcon,
              size: 40,
              color: AppColors.primary,
            ),
          ),
        );
      },
    );
  }
}
