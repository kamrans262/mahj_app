import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loader.dart';
import '../../premium/presentation/premium_plan_screen.dart';
import '../data/subscription_repository.dart';
import '../domain/subscription_plan.dart';
import '../domain/subscription_state.dart';

class SubscriptionEntryScreen extends StatefulWidget {
  const SubscriptionEntryScreen({
    required this.repository,
    super.key,
    this.onBack,
    this.onActivated,
    this.onTermsTap,
    this.onPrivacyPolicyTap,
  });

  final SubscriptionRepository repository;
  final VoidCallback? onBack;
  final VoidCallback? onActivated;
  final VoidCallback? onTermsTap;
  final VoidCallback? onPrivacyPolicyTap;

  @override
  State<SubscriptionEntryScreen> createState() =>
      _SubscriptionEntryScreenState();
}

class _SubscriptionEntryScreenState extends State<SubscriptionEntryScreen> {
  SubscriptionState? _state;
  String? _error;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final state = await widget.repository.fetch();
      if (!mounted) return;
      setState(() => _state = state);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startTrial(SubscriptionPlan plan) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final state = await widget.repository.startTrial(plan.id);
      if (!mounted) return;
      setState(() => _state = state);
      widget.onActivated?.call();
    } catch (error) {
      if (!mounted) return;
      _showMessage(_messageFor(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _messageFor(Object error) {
    if (error is ApiException) return error.message;
    return 'Could not load subscription details. Please try again.';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: Center(child: AppLoader())),
      );
    }

    final state = _state;
    final selectablePlans =
        state?.availablePlans.where((plan) => plan.isSelectable).toList() ??
        const <SubscriptionPlan>[];
    final plan = selectablePlans.isNotEmpty
        ? selectablePlans.first
        : state?.availablePlans.isNotEmpty == true
        ? state!.availablePlans.first
        : null;

    if (_error != null || plan == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error ?? 'No subscription plan is available right now.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body14,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton.primary(label: 'Retry', onPressed: _load),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return PremiumPlanScreen(
      isLoading: _submitting,
      trialDays: plan.trialDays,
      planName: plan.name,
      planDescription: plan.description,
      priceLabel: plan.priceLabel,
      onBack: widget.onBack,
      onStartFreeTrial: () => _startTrial(plan),
      onTermsOfService: widget.onTermsTap,
      onPrivacyPolicy: widget.onPrivacyPolicyTap,
    );
  }
}
