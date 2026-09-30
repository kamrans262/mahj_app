import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_asset_icon.dart';

class InviterUserRow extends StatelessWidget {
  const InviterUserRow({
    required this.avatarAsset,
    required this.inviterName,
    super.key,
    this.avatarUrl,
    this.label = 'Invited by',
  });

  final String avatarAsset;
  final String? avatarUrl;
  final String inviterName;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipOval(
          child: SizedBox(
            width: 40,
            height: 40,
            child: avatarUrl?.trim().isNotEmpty == true
                ? Image.network(
                    avatarUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        AppAssetIcon(assetPath: avatarAsset, size: 40),
                  )
                : AppAssetIcon(assetPath: avatarAsset, size: 40),
          ),
        ),
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
