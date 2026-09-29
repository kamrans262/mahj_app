import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog_field_surface.dart';
import '../../../../core/widgets/app_modal_card.dart';
import '../../domain/match_report.dart';
import 'report_reason_selection_dialog.dart';

typedef ReportDialogSubmitCallback = Future<bool> Function(
  ReportReason reason,
  String notes,
);

class ReportMatchDialog extends StatefulWidget {
  const ReportMatchDialog({
    required this.hostName,
    required this.reasons,
    required this.onCancel,
    required this.onSubmit,
    required this.onSuccess,
    super.key,
  });

  final String hostName;
  final List<ReportReason> reasons;
  final VoidCallback onCancel;
  final ReportDialogSubmitCallback onSubmit;
  final VoidCallback onSuccess;

  @override
  State<ReportMatchDialog> createState() => _ReportMatchDialogState();
}

class _ReportMatchDialogState extends State<ReportMatchDialog> {
  final TextEditingController _notesController = TextEditingController();
  ReportReason? _selectedReason;
  bool _showReasonError = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectReason() async {
    if (_isLoading) return;

    final selected = await showReportReasonSelectionDialog(
      context: context,
      reasons: widget.reasons,
      selectedReason: _selectedReason,
    );

    if (!mounted || selected == null) return;

    setState(() {
      _selectedReason = selected;
      _showReasonError = false;
    });
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    final reason = _selectedReason;
    if (reason == null) {
      setState(() => _showReasonError = true);
      return;
    }

    setState(() => _isLoading = true);

    final succeeded = await widget.onSubmit(
      reason,
      _notesController.text.trim(),
    );

    if (!mounted) return;

    if (succeeded) {
      widget.onSuccess();
      return;
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return PopScope(
      canPop: !_isLoading,
      child: AppModalCard(
        semanticLabel: 'Report ${widget.hostName}',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Report ${widget.hostName}?',
              textAlign: TextAlign.center,
              style: AppTypography.homeMatchTitle18,
            ),
            const SizedBox(height: AppSpacing.micro),
            Text(
              'Please select a reason for reporting',
              textAlign: TextAlign.center,
              style: AppTypography.homeMeta14,
            ),
            const SizedBox(height: AppSpacing.iconGap),
            AppDialogFieldSurface(
              key: const ValueKey('report-reason-field'),
              onTap: _selectReason,
              hasError: _showReasonError,
              semanticLabel: _selectedReason == null
                  ? 'Select a report reason'
                  : 'Selected report reason: ${_selectedReason!.label}',
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedReason?.label ?? 'Select a reason',
                      style: AppTypography.homeMeta14.copyWith(
                        color: _selectedReason == null
                            ? AppColors.textSecondary
                            : AppColors.heading,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            if (_showReasonError) ...[
              const SizedBox(height: AppSpacing.micro),
              Text(
                'Please select a reason.',
                style: AppTypography.homeMeta12.copyWith(
                  color: AppColors.destructive,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.iconGap),
            AppDialogFieldSurface(
              key: const ValueKey('report-notes-field'),
              minHeight: 92,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              semanticLabel: 'Additional notes, optional',
              child: TextField(
                controller: _notesController,
                enabled: !_isLoading,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 3,
                maxLines: 5,
                style: AppTypography.homeMeta14.copyWith(
                  color: AppColors.heading,
                ),
                decoration: InputDecoration.collapsed(
                  hintText: 'Additional notes (optional)',
                  hintStyle: AppTypography.homeMeta12,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final stackActions =
                    textScale > 1.35 || constraints.maxWidth < 200;

                final cancelButton = AppButton.compactSecondary(
                  key: const ValueKey('report-cancel-button'),
                  label: 'Cancel',
                  textStyle: AppTypography.dialogActionButton.copyWith(
                    color: AppColors.primary,
                  ),
                  onPressed: _isLoading ? null : widget.onCancel,
                  isEnabled: !_isLoading,
                );

                final reportButton = AppButton.compactDestructive(
                  key: const ValueKey('report-submit-button'),
                  label: 'Report',
                  textStyle: AppTypography.dialogActionButton,
                  onPressed: _isLoading ? null : _submit,
                  isEnabled: !_isLoading,
                  isLoading: _isLoading,
                );

                if (stackActions) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      cancelButton,
                      const SizedBox(height: AppSpacing.sm),
                      reportButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: cancelButton),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: reportButton),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
