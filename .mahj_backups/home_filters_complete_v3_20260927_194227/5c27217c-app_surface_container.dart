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
    final content = Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.subtleSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.subtleBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.subtleShadow,
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: content,
        ),
      ),
    );
  }
}
