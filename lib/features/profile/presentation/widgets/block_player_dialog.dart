import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog_field_surface.dart';
import '../../../../core/widgets/app_modal_card.dart';
import '../../../matches/domain/match_report.dart';
import '../../../matches/presentation/widgets/report_reason_selection_dialog.dart';

typedef BlockPlayerSubmitCallback = Future<bool> Function(ReportReason reason);

class BlockPlayerDialog extends StatefulWidget {
  const BlockPlayerDialog({
    required this.playerName,
    required this.reasons,
    required this.onCancel,
    required this.onSubmit,
    required this.onSuccess,
    super.key,
  });

  final String playerName;
  final List<ReportReason> reasons;
  final VoidCallback onCancel;
  final BlockPlayerSubmitCallback onSubmit;
  final VoidCallback onSuccess;

  @override
  State<BlockPlayerDialog> createState() => _BlockPlayerDialogState();
}

class _BlockPlayerDialogState extends State<BlockPlayerDialog> {
  ReportReason? _selectedReason;
  bool _showReasonError = false;
  bool _isLoading = false;

  String get _firstName {
    final trimmed = widget.playerName.trim();
    if (trimmed.isEmpty) return 'this player';
    return trimmed.split(RegExp(r'\s+')).first;
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
    final succeeded = await widget.onSubmit(reason);
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
        semanticLabel: 'Block ${widget.playerName}',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Block ${widget.playerName}?',
              textAlign: TextAlign.center,
              style: AppTypography.homeMatchTitle18,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Are you sure you want to block $_firstName?',
              textAlign: TextAlign.center,
              style: AppTypography.homeMeta14,
            ),
            const SizedBox(height: AppSpacing.iconGap),
            Text(
              'This person will not be able to see any matches you propose.',
              textAlign: TextAlign.center,
              style: AppTypography.homeMeta14,
            ),
            const SizedBox(height: AppSpacing.iconGap),
            AppDialogFieldSurface(
              key: const ValueKey('block-reason-field'),
              onTap: _selectReason,
              hasError: _showReasonError,
              semanticLabel: _selectedReason == null
                  ? 'Select a block reason'
                  : 'Selected block reason: ${_selectedReason!.label}',
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
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final stackActions =
                    textScale > 1.35 || constraints.maxWidth < 200;

                final cancelButton = AppButton.compactSecondary(
                  key: const ValueKey('block-cancel-button'),
                  label: 'Cancel',
                  textStyle: AppTypography.dialogActionButton.copyWith(
                    color: AppColors.primary,
                  ),
                  onPressed: _isLoading ? null : widget.onCancel,
                  isEnabled: !_isLoading,
                );

                final blockButton = AppButton.compactDestructive(
                  key: const ValueKey('block-submit-button'),
                  label: 'Block',
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
                      blockButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: cancelButton),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: blockButton),
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
