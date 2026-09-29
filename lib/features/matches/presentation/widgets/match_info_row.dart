import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_asset_icon.dart';

class MatchInfoRow extends StatelessWidget {
  const MatchInfoRow({
    required this.iconAsset,
    required this.label,
    required this.value,
    super.key,
  });

  final String iconAsset;
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final shouldStack = constraints.maxWidth < 320 || textScale > 1.35;

        final labelWidget = _MatchInfoLabel(iconAsset: iconAsset, label: label);

        final alignedValue = ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 20),
          child: Align(alignment: Alignment.centerLeft, child: value),
        );

        if (shouldStack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              labelWidget,
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(left: 25),
                child: alignedValue,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 4, child: labelWidget),
            const SizedBox(width: AppSpacing.lg),
            Expanded(flex: 6, child: alignedValue),
          ],
        );
      },
    );
  }
}

class _MatchInfoLabel extends StatelessWidget {
  const _MatchInfoLabel({required this.iconAsset, required this.label});

  final String iconAsset;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppAssetIcon(
          assetPath: iconAsset,
          size: 20,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.micro),
        Expanded(child: Text(label, style: AppTypography.homeMeta14)),
      ],
    );
  }
}
