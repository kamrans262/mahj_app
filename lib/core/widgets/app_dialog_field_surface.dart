import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';

class AppDialogFieldSurface extends StatelessWidget {
  const AppDialogFieldSurface({
    required this.child,
    super.key,
    this.onTap,
    this.semanticLabel,
    this.hasError = false,
    this.minHeight = 42,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool hasError;
  final double minHeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final material = Material(
      color: AppColors.dialogInputSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        side: BorderSide(
          color: hasError ? AppColors.destructive : AppColors.subtleBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.primary.withValues(alpha: 0.03);
          }
          return null;
        }),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (semanticLabel == null) return material;

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: material,
    );
  }
}
