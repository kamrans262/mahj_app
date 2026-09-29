import 'package:flutter/material.dart';

import '../../../../app/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_asset_icon.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.background,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      elevation: 8,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      selectedLabelStyle: const TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
      ),
      items: const [
        BottomNavigationBarItem(
          icon: _NavigationAssetIcon(
            assetPath: AppAssets.bottomHomeIcon,
            tint: AppColors.textSecondary,
          ),
          activeIcon: _NavigationAssetIcon(
            assetPath: AppAssets.bottomHomeIcon,
            tint: AppColors.primary,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: _NavigationAssetIcon(
            assetPath: AppAssets.bottomMapIcon,
            tint: AppColors.textSecondary,
          ),
          activeIcon: _NavigationAssetIcon(
            assetPath: AppAssets.bottomMapIcon,
            tint: AppColors.primary,
          ),
          label: 'Map',
        ),
        BottomNavigationBarItem(
          icon: _NavigationAssetIcon(
            assetPath: AppAssets.bottomMatchesIcon,
            tint: AppColors.textSecondary,
          ),
          activeIcon: _NavigationAssetIcon(
            assetPath: AppAssets.bottomMatchesIcon,
            tint: AppColors.primary,
          ),
          label: 'My Matches',
        ),
        BottomNavigationBarItem(
          icon: _NavigationAssetIcon(
            assetPath: AppAssets.bottomProfileIcon,
            tint: AppColors.textSecondary,
          ),
          activeIcon: _NavigationAssetIcon(
            assetPath: AppAssets.bottomProfileIcon,
            tint: AppColors.primary,
          ),
          label: 'Profile',
        ),
      ],
    );
  }
}

class _NavigationAssetIcon extends StatelessWidget {
  const _NavigationAssetIcon({required this.assetPath, this.tint});

  final String assetPath;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return AppAssetIcon(assetPath: assetPath, size: 24, color: tint);
  }
}
