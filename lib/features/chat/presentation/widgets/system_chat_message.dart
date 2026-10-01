import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_surface_container.dart';

class SystemChatMessage extends StatelessWidget {
  const SystemChatMessage({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: AppSurfaceContainer(
        minHeight: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTypography.homeMeta14,
        ),
      ),
    );
  }
}
