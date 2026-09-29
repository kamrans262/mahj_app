import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_asset_icon.dart';
import '../../../../core/widgets/app_surface_container.dart';

class SettingsItemData {
  const SettingsItemData({
    required this.id,
    required this.title,
    required this.iconAsset,
    required this.trailingAsset,
    required this.onTap,
  });

  final String id;
  final String title;
  final String iconAsset;
  final String trailingAsset;
  final VoidCallback onTap;
}

class SettingsSection extends StatelessWidget {
  const SettingsSection({required this.items, super.key, this.label});

  final String? label;
  final List<SettingsItemData> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTypography.homeMeta14),
          const SizedBox(height: AppSpacing.sm),
        ],
        AppSurfaceContainer(
          minHeight: 0,
          padding: EdgeInsets.zero,
          backgroundColor: AppColors.background,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < items.length; index++) ...[
                _SettingsRow(item: items[index]),
                if (index < items.length - 1)
                  const Divider(height: 1, color: AppColors.divider),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.item});

  final SettingsItemData item;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: item.title,
      child: InkWell(
        key: ValueKey('settings-row-${item.id}'),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              AppAssetIcon(
                assetPath: item.iconAsset,
                size: 18,
                color: AppColors.heading,
              ),
              const SizedBox(width: AppSpacing.micro),
              Expanded(
                child: Text(
                  item.title,
                  softWrap: true,
                  style: AppTypography.body16.copyWith(
                    color: AppColors.heading,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppAssetIcon(
                assetPath: item.trailingAsset,
                size: 18,
                color: AppColors.heading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
