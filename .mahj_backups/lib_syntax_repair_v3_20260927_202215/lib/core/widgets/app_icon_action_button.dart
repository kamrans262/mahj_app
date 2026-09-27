import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import 'app_asset_icon.dart';
import 'app_loader.dart';

class AppIconActionButton extends StatelessWidget {
  const AppIconActionButton({
    required this.onPressed,
    super.key,
    this.assetPath,
    this.fallbackIcon = Icons.send,
    this.isLoading = false,
    this.semanticLabel = 'Action',
    this.iconKey,
  });

  final VoidCallback? onPressed;
  final String? assetPath;
  final IconData fallbackIcon;
  final bool isLoading;
  final String semanticLabel;
  final Key? iconKey;

  static const double size = 48;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox.square(
        dimension: size,
        child: Material(
          color: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
            side: const BorderSide(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return AppColors.primary.withValues(alpha: 0.05);
              }
              return null;
            }),
            child: Center(
              child: isLoading
                  ? const AppLoader(
                      size: 22,
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    )
                  : assetPath != null && assetPath!.isNotEmpty
                      ? AppAssetIcon(
                          key: iconKey,
                          assetPath: assetPath!,
                          size: 24,
                        )
                      : Icon(
                          fallbackIcon,
                          key: iconKey,
                          size: 24,
                          color: AppColors.textSecondary,
                        ),
            ),
          ),
        ),
      ),
    );
  }
}
