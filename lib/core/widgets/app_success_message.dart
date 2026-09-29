import 'package:flutter/material.dart';

import '../../app/app_assets.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import 'app_asset_icon.dart';
import 'app_surface_container.dart';

class AppSuccessMessage extends StatelessWidget {
  const AppSuccessMessage({
    required this.message,
    super.key,
    this.iconAsset = AppAssets.approveIcon,
  });

  final String message;
  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceContainer(
      minHeight: 0,
      borderRadius: AppRadius.control,
      backgroundColor: AppColors.matchSuccess.withValues(alpha: 0.12),
      borderColor: AppColors.matchSuccess.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          AppAssetIcon(assetPath: iconAsset, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: AppTypography.homeMeta14.copyWith(
                color: AppColors.heading,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
