import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_asset_icon.dart';

class InviterUserRow extends StatelessWidget {
  const InviterUserRow({
    required this.avatarAsset,
    required this.inviterName,
    super.key,
    this.label = 'Invited by',
  });

  final String avatarAsset;
  final String inviterName;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipOval(child: AppAssetIcon(assetPath: avatarAsset, size: 40)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: AppTypography.homeMeta14),
              const SizedBox(height: AppSpacing.micro),
              Text(
                inviterName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.homeMatchTitle18,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
