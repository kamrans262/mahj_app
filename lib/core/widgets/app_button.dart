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
  }) : _variant = _AppButtonVariant.primary,
       _compact = false;

  const AppButton.compactPrimary({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.isEnabled = true,
    this.leading,
  }) : _variant = _AppButtonVariant.primary,
       _compact = true;

  const AppButton.outlined({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.isEnabled = true,
    this.leading,
  }) : _variant = _AppButtonVariant.outlined,
       _compact = false;

  const AppButton.secondary({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.isEnabled = true,
    this.leading,
  }) : _variant = _AppButtonVariant.secondary,
       _compact = false;

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Widget? leading;
  final _AppButtonVariant _variant;
  final bool _compact;

  static const double height = 48;
  static const double compactHeight = 42;

  @override
  Widget build(BuildContext context) {
    final enabled = isEnabled && !isLoading && onPressed != null;
    final isPrimary = _variant == _AppButtonVariant.primary;
    final isSecondary = _variant == _AppButtonVariant.secondary;

    final background = isPrimary
        ? (enabled ? AppColors.primary : AppColors.disabled)
        : AppColors.background;
    final borderColor = isSecondary ? AppColors.primary : AppColors.border;
    final textStyle = _compact
        ? AppTypography.compactPrimaryButton
        : isPrimary
        ? AppTypography.primaryButton
        : isSecondary
        ? AppTypography.secondaryButton
        : AppTypography.socialButton;

    final material = Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        side: isPrimary ? BorderSide.none : BorderSide(color: borderColor),
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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: _compact ? 25 : 0),
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
                      if (_compact)
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textStyle,
                        )
                      else
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textStyle,
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );

    if (_compact) {
      return SizedBox(height: compactHeight, child: material);
    }

    return SizedBox(
      width: double.infinity,
      height: height,
      child: material,
    );
  }
}

enum _AppButtonVariant { primary, outlined, secondary }
