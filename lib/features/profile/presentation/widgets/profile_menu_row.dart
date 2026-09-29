import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_asset_icon.dart';

class ProfileMenuRow extends StatelessWidget {
  const ProfileMenuRow({
    required this.iconAsset,
    required this.label,
    required this.trailingAsset,
    super.key,
    this.onTap,
  });

  final String iconAsset;
  final String label;
  final String trailingAsset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppColors.background,
        child: InkWell(
          onTap: onTap ?? () {},
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Row(
                children: [
                  AppAssetIcon(
                    assetPath: iconAsset,
                    size: 24,
                    color: AppColors.heading,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.homeMatchTitle16,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppAssetIcon(
                    assetPath: trailingAsset,
                    size: 20,
                    color: AppColors.heading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
