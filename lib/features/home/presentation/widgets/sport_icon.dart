import 'package:flutter/material.dart';

import '../../../../app/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_asset_icon.dart';
import '../../domain/home_match.dart';

abstract final class SportIconResolver {
  static String assetForKey(String iconKey) {
    return switch (iconKey) {
      'football' => AppAssets.americanFootballIcon,
      'basketball' => AppAssets.basketballIcon,
      'baseball' => AppAssets.baseballIcon,
      'soccer' => AppAssets.homeFootballIcon,
      'tennis' => AppAssets.tennisIcon,
      'volleyball' => AppAssets.volleyballIcon,
      'hockey' => AppAssets.hockeyIcon,
      'pickleball' => AppAssets.pickleballIcon,
      'golf' => AppAssets.golfIcon,
      'softball' => AppAssets.baseballIcon,
      'lacrosse' => AppAssets.lacrosseIcon,
      _ => AppAssets.genericSportIcon,
    };
  }

  static String assetFor(HomeMatch match) {
    if (match.sportIconAsset.isNotEmpty) {
      return match.sportIconAsset;
    }

    if (match.sportIconKey.isNotEmpty) {
      return assetForKey(match.sportIconKey);
    }

    final sport = match.sportName.toLowerCase();
    if (sport.contains('american football')) {
      return AppAssets.americanFootballIcon;
    }
    if (sport.contains('basket')) return AppAssets.basketballIcon;
    if (sport.contains('baseball') || sport.contains('softball')) {
      return AppAssets.baseballIcon;
    }
    if (sport.contains('soccer') || sport == 'football') {
      return AppAssets.homeFootballIcon;
    }
    if (sport.contains('tennis')) return AppAssets.tennisIcon;
    if (sport.contains('volley')) return AppAssets.volleyballIcon;
    if (sport.contains('hockey')) return AppAssets.hockeyIcon;
    if (sport.contains('pickle')) return AppAssets.pickleballIcon;
    if (sport.contains('golf')) return AppAssets.golfIcon;
    if (sport.contains('lacrosse')) return AppAssets.lacrosseIcon;

    return AppAssets.genericSportIcon;
  }
}

class SportIcon extends StatelessWidget {
  const SportIcon({required this.match, super.key, this.size = 24});

  final HomeMatch match;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AppAssetIcon(
      assetPath: SportIconResolver.assetFor(match),
      size: size,
    );
  }
}
