import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

class _SubscriptionEntryScreenState extends State<SubscriptionEntryScreen>
    with WidgetsBindingObserver {
  SubscriptionState? _state;
  String? _error;
  bool _loading = true;
  bool _submitting = false;
  bool _waitingForCheckout = false;
  bool _refreshingCheckout = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForCheckout) {
      _refreshAfterCheckout();
    }
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
      final result = await widget.repository.startTrial(plan.id);
      if (!mounted) return;

      if (result.requiresCheckout) {
        final checkoutUrl = Uri.tryParse(result.checkoutUrl!);
        if (checkoutUrl == null) {
          throw const FormatException('Invalid Stripe checkout URL.');
        }

        final opened = await launchUrl(
          checkoutUrl,
          mode: LaunchMode.externalApplication,
        );

        if (!opened) {
          throw StateError('Could not open Stripe checkout.');
        }

        if (!mounted) return;
        setState(() {
          _state = result.state;
          _waitingForCheckout = true;
        });
        _showMessage(
          'Complete the secure Stripe checkout, then return to Mahj.',
        );
        return;
      }

      setState(() => _state = result.state);
      widget.onActivated?.call();
    } catch (error) {
      if (!mounted) return;
      _showMessage(_messageFor(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _refreshAfterCheckout() async {
    if (_refreshingCheckout) return;
    _refreshingCheckout = true;

    try {
      for (var attempt = 0; attempt < 4; attempt++) {
        if (attempt > 0) {
          await Future<void>.delayed(const Duration(seconds: 1));
        }

        final state = await widget.repository.fetch();
        if (!mounted) return;

        setState(() => _state = state);

        if (state.status == 'trialing' || state.status == 'active') {
          _waitingForCheckout = false;
          widget.onActivated?.call();
          return;
        }
      }

      if (!mounted) return;
      _waitingForCheckout = false;
      _showMessage(
        'Stripe is still confirming your subscription. Please try again in a moment.',
      );
    } catch (error) {
      if (!mounted) return;
      _waitingForCheckout = false;
      _showMessage(_messageFor(error));
    } finally {
      _refreshingCheckout = false;
    }
  }

  String _messageFor(Object error) {
    if (error is ApiException) return error.message;
    if (error is StateError || error is FormatException) {
      return error.toString().replaceFirst(RegExp(r'^[^:]+:\s*'), '');
    }
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
      isLoading: _submitting || _refreshingCheckout,
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
