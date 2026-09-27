import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../core/widgets/app_asset_icon.dart';
import '../../../../core/widgets/app_loader.dart';

class AuthSubmitIconButton extends StatelessWidget {
  const AuthSubmitIconButton({
    required this.onPressed,
    super.key,
    this.assetPath,
    this.isLoading = false,
    this.semanticLabel = 'Send reset link',
  });

  final VoidCallback? onPressed;
  final String? assetPath;
  final bool isLoading;
  final String semanticLabel;

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
                  : assetPath != null
                  ? AppAssetIcon(
                      key: const ValueKey('forgot-send-icon'),
                      assetPath: assetPath!,
                      size: 24,
                    )
                  : const Icon(
                      Icons.send_outlined,
                      key: ValueKey('forgot-send-icon'),
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
