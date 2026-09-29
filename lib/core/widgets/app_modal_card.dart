import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';

class AppModalCard extends StatelessWidget {
  const AppModalCard({required this.child, super.key, this.semanticLabel});

  final Widget child;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final surface = Material(
      color: Colors.transparent,
      child: DefaultTextStyle.merge(
        // Dialog routes created with showGeneralDialog do not automatically
        // insert Material's normal DefaultTextStyle. Explicitly clearing any
        // inherited debug decoration prevents the yellow underline that can
        // otherwise appear under modal text in debug builds.
        style: const TextStyle(decoration: TextDecoration.none),
        child: Container(
          key: const ValueKey('app-modal-card-surface'),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.subtleSurface,
            borderRadius: BorderRadius.circular(AppRadius.sheetTop),
            border: Border.all(color: AppColors.subtleBorder),
            boxShadow: const [
              BoxShadow(
                color: AppColors.confirmationDialogShadow,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Padding(
            key: const ValueKey('app-modal-card-padding'),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.confirmationDialogHorizontal,
              vertical: AppSpacing.confirmationDialogVertical,
            ),
            child: child,
          ),
        ),
      ),
    );

    if (semanticLabel == null) return surface;

    return Semantics(
      container: true,
      namesRoute: true,
      label: semanticLabel,
      explicitChildNodes: true,
      child: surface,
    );
  }
}
