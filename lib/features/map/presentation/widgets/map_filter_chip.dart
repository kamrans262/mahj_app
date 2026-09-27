import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_surface_container.dart';

class MapFilterChip extends StatelessWidget {
  const MapFilterChip({
    required this.label,
    required this.semanticLabel,
    required this.onTap,
    super.key,
    this.selected = true,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      value: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 80,
          minHeight: 32,
        ),
        child: AppSurfaceContainer(
          onTap: onTap,
          minHeight: 32,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.homeMeta14.copyWith(
              color: AppColors.heading,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}
