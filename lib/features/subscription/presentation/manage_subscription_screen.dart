import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../core/widgets/app_loader.dart';
import '../domain/subscription_plan.dart';
import 'widgets/subscription_plan_card.dart';

class ManageSubscriptionScreen extends StatefulWidget {
  const ManageSubscriptionScreen({
    required this.currentPlan,
    required this.availablePlans,
    super.key,
    this.isLoading = false,
    this.requiresPayment = false,
    this.errorMessage,
    this.onBack,
    this.onRetry,
    this.onConfirmPayment,
    this.onConfirmChange,
    this.onCancelSubscription,
    this.onTermsTap,
    this.onPrivacyPolicyTap,
  });

  final SubscriptionPlan currentPlan;
  final List<SubscriptionPlan> availablePlans;
  final bool isLoading;
  final bool requiresPayment;
  final String? errorMessage;
  final VoidCallback? onBack;
  final VoidCallback? onRetry;
  final Future<bool> Function(SubscriptionPlan plan)? onConfirmPayment;
  final Future<bool> Function(SubscriptionPlan plan)? onConfirmChange;
  final Future<bool> Function()? onCancelSubscription;
  final VoidCallback? onTermsTap;
  final VoidCallback? onPrivacyPolicyTap;

  @override
  State<ManageSubscriptionScreen> createState() =>
      _ManageSubscriptionScreenState();
}

class _ManageSubscriptionScreenState extends State<ManageSubscriptionScreen> {
  late SubscriptionPlan _currentPlan;
  String? _selectedPlanId;
  bool _dialogOpen = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _currentPlan = widget.currentPlan;
  }

  @override
  void didUpdateWidget(covariant ManageSubscriptionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPlan.id != widget.currentPlan.id ||
        oldWidget.currentPlan.statusText != widget.currentPlan.statusText ||
        oldWidget.currentPlan.renewalText != widget.currentPlan.renewalText) {
      _currentPlan = widget.currentPlan;
      if (_selectedPlanId == _currentPlan.id) {
        _selectedPlanId = null;
      }
    }
  }

  List<SubscriptionPlan> get _alternativePlans => widget.availablePlans
      .where((plan) => plan.id != _currentPlan.id && plan.isSelectable)
      .toList(growable: false);

  SubscriptionPlan? get _selectedPlan {
    for (final plan in _alternativePlans) {
      if (plan.id == _selectedPlanId) return plan;
    }
    return null;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _selectPlan(SubscriptionPlan plan) {
    if (!plan.isSelectable || plan.id == _currentPlan.id) return;
    setState(() {
      _selectedPlanId = plan.id;
    });
  }

  Future<void> _startPayment() async {
    final selectedPlan = _selectedPlan;
    if (selectedPlan == null) {
      _showMessage('Choose a plan before confirming payment.');
      return;
    }
    if (_submitting) return;

    final callback = widget.onConfirmPayment;
    if (callback == null) {
      _showMessage('Subscription service is not connected yet.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await callback(selectedPlan);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openConfirmation() async {
    final selectedPlan = _selectedPlan;
    if (selectedPlan == null) {
      _showMessage('Choose a plan before confirming changes.');
      return;
    }
    if (_dialogOpen || _submitting) return;

    _dialogOpen = true;
    var serviceUnavailable = false;
    try {
      final changed = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Confirm subscription changes',
        barrierColor: AppColors.confirmationBackdrop,
        transitionDuration: const Duration(milliseconds: 160),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          var dialogLoading = false;
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final navigator = Navigator.of(dialogContext);

              Future<void> confirm() async {
                if (dialogLoading || _submitting) return;
                final callback = widget.onConfirmChange;
                if (callback == null) {
                  serviceUnavailable = true;
                  navigator.pop(false);
                  return;
                }

                setDialogState(() => dialogLoading = true);
                _submitting = true;
                bool success;
                try {
                  success = await callback(selectedPlan);
                } catch (_) {
                  success = false;
                } finally {
                  _submitting = false;
                }

                if (!navigator.mounted) return;
                if (success) {
                  navigator.pop(true);
                } else {
                  setDialogState(() => dialogLoading = false);
                  _showMessage(
                    'Could not update the subscription. Please try again.',
                  );
                }
              }

              return PopScope(
                canPop: !dialogLoading,
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pageHorizontal,
                        vertical: AppSpacing.lg,
                      ),
                      child: AppConfirmationDialog(
                        title: 'Confirm Changes',
                        message:
                            'Are you sure you want to switch to the ${selectedPlan.name}?',
                        cancelLabel: 'Cancel',
                        confirmLabel: 'Confirm',
                        isLoading: dialogLoading,
                        onCancel: dialogLoading
                            ? null
                            : () => navigator.pop(false),
                        onConfirm: dialogLoading ? null : confirm,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      );

      if (!mounted) return;
      if (changed == true) {
        setState(() => _selectedPlanId = null);
        _showMessage('Subscription updated');
      } else if (serviceUnavailable) {
        _showMessage('Subscription service is not connected yet.');
      }
    } finally {
      _dialogOpen = false;
    }
  }

  Future<void> _openCancellation() async {
    final callback = widget.onCancelSubscription;
    if (callback == null || _dialogOpen || _submitting) return;

    _dialogOpen = true;
    try {
      final canceled = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Cancel subscription',
        barrierColor: AppColors.confirmationBackdrop,
        transitionDuration: const Duration(milliseconds: 160),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          var dialogLoading = false;
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final navigator = Navigator.of(dialogContext);

              Future<void> confirm() async {
                if (dialogLoading || _submitting) return;
                setDialogState(() => dialogLoading = true);
                _submitting = true;
                bool success;
                try {
                  success = await callback();
                } catch (_) {
                  success = false;
                } finally {
                  _submitting = false;
                }

                if (!navigator.mounted) return;
                if (success) {
                  navigator.pop(true);
                } else {
                  setDialogState(() => dialogLoading = false);
                }
              }

              return PopScope(
                canPop: !dialogLoading,
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pageHorizontal,
                        vertical: AppSpacing.lg,
                      ),
                      child: AppConfirmationDialog(
                        title: 'Cancel Subscription?',
                        message: 'Your current access will remain available until the end of the current period.',
                        cancelLabel: 'Keep Plan',
                        confirmLabel: 'Cancel Plan',
                        isLoading: dialogLoading,
                        confirmVariant: AppConfirmationVariant.destructive,
                        onCancel: dialogLoading
                            ? null
                            : () => navigator.pop(false),
                        onConfirm: dialogLoading ? null : confirm,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

      if (!mounted) return;
      if (canceled == true) {
        _showMessage('Subscription cancellation saved.');
      }
    } finally {
      _dialogOpen = false;
    }
  }

  VoidCallback _linkAction(VoidCallback? callback, String label) {
    return callback ?? () => _showMessage('$label is not connected yet.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('manage-subscription-screen'),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.lg,
                AppSpacing.pageHorizontal,
                0,
              ),
              child: AppCenteredPageHeader(
                title: 'Manage Subscription',
                onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(child: _buildScrollableContent()),
            if (!widget.isLoading && widget.errorMessage == null)
              _SubscriptionBottomArea(
                infoText: _selectedPlan?.infoText,
                confirmLabel: widget.requiresPayment
                    ? 'Confirm Payment'
                    : 'Confirm Changes',
                isSubmitting: _submitting,
                onConfirm: _alternativePlans.isEmpty
                    ? null
                    : widget.requiresPayment
                    ? _startPayment
                    : _openConfirmation,
                onCancel: widget.onCancelSubscription == null
                    ? null
                    : _openCancellation,
                onTermsTap: _linkAction(widget.onTermsTap, 'Terms of Service'),
                onPrivacyPolicyTap: _linkAction(
                  widget.onPrivacyPolicyTap,
                  'Privacy Policy',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableContent() {
    if (widget.isLoading) {
      return const Center(child: AppLoader());
    }

    if (widget.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.body14,
              ),
              if (widget.onRetry != null) ...[
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: widget.onRetry,
                  child: Text('Retry', style: AppTypography.action14),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final alternativePlans = _alternativePlans;

    return ListView(
      key: const ValueKey('manage-subscription-scroll-view'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        25,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      children: [
        Text('Current Plan', style: AppTypography.homeMeta14),
        const SizedBox(height: AppSpacing.xs),
        SubscriptionPlanCard(
          plan: _currentPlan,
          isCurrentSelectionActive: _selectedPlanId == null,
        ),
        if (alternativePlans.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Choose Your Plan', style: AppTypography.homeMeta14),
          const SizedBox(height: AppSpacing.xs),
          for (var index = 0; index < alternativePlans.length; index++) ...[
            Builder(
              builder: (context) {
                final plan = alternativePlans[index];
                return SubscriptionPlanCard(
                  plan: plan,
                  isSelected: _selectedPlanId == plan.id,
                  onTap: () => _selectPlan(plan),
                );
              },
            ),
            if (index < alternativePlans.length - 1)
              const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ],
    );
  }
}

class _SubscriptionBottomArea extends StatelessWidget {
  const _SubscriptionBottomArea({
    this.infoText,
    this.confirmLabel = 'Confirm Changes',
    this.isSubmitting = false,
    this.onConfirm,
    this.onCancel,
    required this.onTermsTap,
    required this.onPrivacyPolicyTap,
  });

  final String? infoText;
  final String confirmLabel;
  final bool isSubmitting;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyPolicyTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.sm,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onConfirm != null) ...[
            AppButton.primary(
              key: const ValueKey('manage-subscription-confirm'),
              label: confirmLabel,
              onPressed: onConfirm,
              isLoading: isSubmitting,
              isEnabled: !isSubmitting,
            ),
            if (infoText != null && infoText!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                infoText!,
                textAlign: TextAlign.center,
                style: AppTypography.action14,
              ),
            ],
          ],
          if (onCancel != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton.destructiveOutlined(
              key: const ValueKey('manage-subscription-cancel'),
              label: 'Cancel Plan',
              textStyle: AppTypography.matchSuccessSecondaryButton.copyWith(
                color: AppColors.destructive,
              ),
              onPressed: isSubmitting ? null : onCancel,
            ),
          ],
          const SizedBox(height: 36),
          _SubscriptionLegalText(
            onTermsTap: onTermsTap,
            onPrivacyPolicyTap: onPrivacyPolicyTap,
          ),
        ],
      ),
    );
  }
}

class _SubscriptionLegalText extends StatelessWidget {
  const _SubscriptionLegalText({
    required this.onTermsTap,
    required this.onPrivacyPolicyTap,
  });

  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyPolicyTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 2,
      runSpacing: 2,
      children: [
        Text('By continuing, you agree to our', style: AppTypography.legal12),
        Semantics(
          button: true,
          label: 'Terms of Service',
          child: InkWell(
            key: const ValueKey('manage-subscription-terms'),
            onTap: onTermsTap,
            child: Text('terms of services', style: AppTypography.legal12),
          ),
        ),
        Text('and', style: AppTypography.legal12),
        Semantics(
          button: true,
          label: 'Privacy Policy',
          child: InkWell(
            key: const ValueKey('manage-subscription-privacy'),
            onTap: onPrivacyPolicyTap,
            child: Text('privacy policy', style: AppTypography.legal12),
          ),
        ),
      ],
    );
  }
}
