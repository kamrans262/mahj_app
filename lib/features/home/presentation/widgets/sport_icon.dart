import 'package:flutter/material.dart';

import '../../../../app/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_asset_icon.dart';
import '../../domain/home_match.dart';

abstract final class SportIconResolver {
  static String? assetFor(HomeMatch match) {
    if (match.sportIconAsset.isNotEmpty) {
      return match.sportIconAsset;
    }

    final sport = match.sportName.toLowerCase();

    if (sport.contains('basket')) {
      return AppAssets.basketballIcon;
    }

    if (sport.contains('football') || sport.contains('soccer')) {
      return AppAssets.homeFootballIcon;
    }

    return null;
  }
}

class SportIcon extends StatelessWidget {
  const SportIcon({required this.match, super.key, this.size = 24});

  final HomeMatch match;
  final double size;

  @override
  Widget build(BuildContext context) {
    final assetPath = SportIconResolver.assetFor(match);

    if (assetPath != null) {
      return AppAssetIcon(assetPath: assetPath, size: size);
    }

    return Icon(Icons.sports, size: size, color: AppColors.heading);
  }
}
