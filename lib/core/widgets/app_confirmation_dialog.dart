import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import 'app_button.dart';
import 'app_modal_card.dart';

enum AppConfirmationVariant { primary, destructive }

class AppConfirmationDialog extends StatelessWidget {
  const AppConfirmationDialog({
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    super.key,
    this.isLoading = false,
    this.confirmVariant = AppConfirmationVariant.primary,
  });

  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final bool isLoading;
  final AppConfirmationVariant confirmVariant;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return AppModalCard(
      semanticLabel: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.homeMatchTitle18,
          ),
          const SizedBox(height: AppSpacing.micro),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.homeMeta14,
          ),
          const SizedBox(height: AppSpacing.confirmationDialogActionGap),
          LayoutBuilder(
            builder: (context, constraints) {
              final stackActions =
                  textScale > 1.35 || constraints.maxWidth < 200;

              final cancelButton = AppButton.compactSecondary(
                key: const ValueKey('confirmation-cancel-button'),
                label: cancelLabel,
                textStyle: AppTypography.dialogActionButton.copyWith(
                  color: AppColors.primary,
                ),
                onPressed: isLoading ? null : onCancel,
                isEnabled: !isLoading,
              );

              final confirmButton =
                  confirmVariant == AppConfirmationVariant.destructive
                  ? AppButton.compactDestructive(
                      key: const ValueKey('confirmation-confirm-button'),
                      label: confirmLabel,
                      textStyle: AppTypography.dialogActionButton,
                      onPressed: isLoading ? null : onConfirm,
                      isLoading: isLoading,
                      isEnabled: !isLoading,
                    )
                  : AppButton.compactPrimary(
                      key: const ValueKey('confirmation-confirm-button'),
                      label: confirmLabel,
                      textStyle: AppTypography.dialogActionButton,
                      onPressed: isLoading ? null : onConfirm,
                      isLoading: isLoading,
                      isEnabled: !isLoading,
                    );

              if (stackActions) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    cancelButton,
                    const SizedBox(height: AppSpacing.sm),
                    confirmButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: cancelButton),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: confirmButton),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
