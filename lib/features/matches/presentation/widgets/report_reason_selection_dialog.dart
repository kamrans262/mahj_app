import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/match_report.dart';

Future<ReportReason?> showReportReasonSelectionDialog({
  required BuildContext context,
  required List<ReportReason> reasons,
  required ReportReason? selectedReason,
}) {
  return showDialog<ReportReason>(
    context: context,
    barrierColor: AppColors.confirmationBackdrop,
    builder: (dialogContext) {
      final listHeight = (reasons.length * 56.0).clamp(56.0, 280.0).toDouble();

      return Dialog(
        key: const ValueKey('report-reason-selection-dialog'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageHorizontal,
          vertical: AppSpacing.lg,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.controlBorder),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Select a reason',
                  textAlign: TextAlign.center,
                  style: AppTypography.homeMatchTitle18,
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: listHeight,
                  child: ListView.builder(
                    key: const ValueKey('report-reason-options-list'),
                    padding: EdgeInsets.zero,
                    itemCount: reasons.length,
                    itemBuilder: (context, index) {
                      final reason = reasons[index];
                      final isSelected = reason.id == selectedReason?.id;

                      return InkWell(
                        key: ValueKey('report-reason-option-${reason.id}'),
                        borderRadius: BorderRadius.circular(AppRadius.control),
                        onTap: () => Navigator.of(dialogContext).pop(reason),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 56),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    reason.label,
                                    style: AppTypography.homeMeta14.copyWith(
                                      color: AppColors.heading,
                                    ),
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  const Icon(
                                    Icons.check_circle,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
