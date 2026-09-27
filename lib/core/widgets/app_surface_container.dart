import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';

class AppSurfaceContainer extends StatelessWidget {
  const AppSurfaceContainer({
    required this.child,
    super.key,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 12,
    ),
    this.minHeight = 48,
    this.semanticsLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double minHeight;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [
          BoxShadow(
            color: AppColors.subtleShadow,
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Material(
        color: AppColors.subtleSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.subtleBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primary.withValues(alpha: 0.03);
            }
            return Colors.transparent;
          }),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );

    if (onTap == null) return surface;

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: surface,
    );
  }
}
