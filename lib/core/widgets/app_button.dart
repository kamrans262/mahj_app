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
    this.textStyle,
  }) : _variant = _AppButtonVariant.primary,
       _compact = false;

  const AppButton.compactPrimary({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.isEnabled = true,
    this.leading,
    this.textStyle,
  }) : _variant = _AppButtonVariant.primary,
       _compact = true;

  const AppButton.compactSecondary({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.isEnabled = true,
    this.leading,
    this.textStyle,
  }) : _variant = _AppButtonVariant.secondary,
       _compact = true;

  const AppButton.compactDestructive({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.isEnabled = true,
    this.leading,
    this.textStyle,
  }) : _variant = _AppButtonVariant.destructive,
       _compact = true;

  const AppButton.destructive({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.isEnabled = true,
    this.leading,
    this.textStyle,
  }) : _variant = _AppButtonVariant.destructive,
       _compact = false;

  const AppButton.destructiveOutlined({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.isEnabled = true,
    this.leading,
    this.textStyle,
  }) : _variant = _AppButtonVariant.destructiveOutlined,
       _compact = false;

  const AppButton.outlined({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.isEnabled = true,
    this.leading,
    this.textStyle,
  }) : _variant = _AppButtonVariant.outlined,
       _compact = false;

  const AppButton.secondary({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.isEnabled = true,
    this.leading,
    this.textStyle,
  }) : _variant = _AppButtonVariant.secondary,
       _compact = false;

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Widget? leading;
  final TextStyle? textStyle;
  final _AppButtonVariant _variant;
  final bool _compact;

  static const double height = 48;
  static const double compactHeight = 42;

  @override
  Widget build(BuildContext context) {
    final enabled = isEnabled && !isLoading && onPressed != null;
    final isPrimary = _variant == _AppButtonVariant.primary;
    final isSecondary = _variant == _AppButtonVariant.secondary;
    final isDestructive = _variant == _AppButtonVariant.destructive;
    final isDestructiveOutlined =
        _variant == _AppButtonVariant.destructiveOutlined;

    final background = isPrimary
        ? (enabled ? AppColors.primary : AppColors.disabled)
        : isDestructive
        ? (enabled ? AppColors.destructive : AppColors.disabled)
        : AppColors.background;

    final borderColor = isSecondary
        ? AppColors.primary
        : isDestructiveOutlined
        ? AppColors.destructive
        : AppColors.border;

    final effectiveTextStyle =
        textStyle ??
        (_compact
            ? isPrimary || isDestructive
                  ? AppTypography.compactPrimaryButton
                  : isSecondary
                  ? AppTypography.compactPrimaryButton.copyWith(
                      color: AppColors.primary,
                    )
                  : AppTypography.socialButton
            : isPrimary
            ? AppTypography.primaryButton
            : isSecondary
            ? AppTypography.secondaryButton
            : isDestructiveOutlined
            ? AppTypography.secondaryButton.copyWith(
                color: AppColors.destructive,
              )
            : AppTypography.socialButton);

    Widget labelContent;
    if (isLoading) {
      labelContent = AppLoader(
        size: 22,
        strokeWidth: 2.5,
        color: isPrimary || isDestructive
            ? Colors.white
            : isDestructiveOutlined
            ? AppColors.destructive
            : AppColors.primary,
      );
    } else {
      labelContent = Row(
        // Compact buttons are often measured as non-flex children of a Row.
        // In that situation Flutter intentionally gives them an unbounded
        // horizontal constraint. A flex child inside a max-sized Row is
        // invalid under those constraints and causes the entire render tree
        // to fail. Shrink-wrap the label row instead; Flexible uses a loose
        // fit and still truncates safely when the parent provides a finite
        // width.
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 14)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: effectiveTextStyle,
            ),
          ),
        ],
      );
    }

    final material = Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        side: isPrimary || isDestructive
            ? BorderSide.none
            : BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (!states.contains(WidgetState.pressed)) return null;

          if (isPrimary || isDestructive) {
            return Colors.black.withValues(alpha: 0.08);
          }

          if (isDestructiveOutlined) {
            return AppColors.destructive.withValues(alpha: 0.05);
          }

          return AppColors.primary.withValues(alpha: 0.05);
        }),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = !_compact
                ? 0.0
                : constraints.maxWidth >= 160
                ? 25.0
                : 12.0;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Center(child: labelContent),
            );
          },
        ),
      ),
    );

    if (_compact) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: compactHeight),
        child: material,
      );
    }

    return SizedBox(width: double.infinity, height: height, child: material);
  }
}

enum _AppButtonVariant {
  primary,
  outlined,
  secondary,
  destructive,
  destructiveOutlined,
}
