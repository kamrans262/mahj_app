import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import 'app_loader.dart';

class AppButton extends StatelessWidget {
  const AppButton.primary({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.isEnabled = true,
    this.leading,
  }) : _variant = _AppButtonVariant.primary;

  const AppButton.outlined({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.isEnabled = true,
    this.leading,
  }) : _variant = _AppButtonVariant.outlined;

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Widget? leading;
  final _AppButtonVariant _variant;

  static const double height = 48;

  @override
  Widget build(BuildContext context) {
    final enabled = isEnabled && !isLoading && onPressed != null;
    final isPrimary = _variant == _AppButtonVariant.primary;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Material(
        color: isPrimary
            ? (enabled ? AppColors.primary : AppColors.disabled)
            : AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          side: isPrimary
              ? BorderSide.none
              : const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return isPrimary
                  ? Colors.black.withValues(alpha: 0.08)
                  : AppColors.primary.withValues(alpha: 0.05);
            }
            return null;
          }),
          child: Center(
            child: isLoading
                ? AppLoader(
                    size: 22,
                    strokeWidth: 2.5,
                    color: isPrimary ? Colors.white : AppColors.primary,
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: 14),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: isPrimary
                              ? AppTypography.primaryButton
                              : AppTypography.socialButton,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

enum _AppButtonVariant { primary, outlined }
