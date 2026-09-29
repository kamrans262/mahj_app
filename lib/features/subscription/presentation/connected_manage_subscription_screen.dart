import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../data/subscription_repository.dart';
import '../domain/subscription_plan.dart';
import '../domain/subscription_state.dart';
import 'manage_subscription_screen.dart';

class ConnectedManageSubscriptionScreen extends StatefulWidget {
  const ConnectedManageSubscriptionScreen({
    required this.repository,
    super.key,
    this.onBack,
    this.onTermsTap,
    this.onPrivacyPolicyTap,
  });

  final SubscriptionRepository repository;
  final VoidCallback? onBack;
  final VoidCallback? onTermsTap;
  final VoidCallback? onPrivacyPolicyTap;

  @override
  State<ConnectedManageSubscriptionScreen> createState() =>
      _ConnectedManageSubscriptionScreenState();
}

class _ConnectedManageSubscriptionScreenState
    extends State<ConnectedManageSubscriptionScreen> {
  SubscriptionState? _state;
  String? _error;
  bool _loading = true;

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

  Future<bool> _changePlan(SubscriptionPlan plan) async {
    try {
      final state = await widget.repository.changePlan(plan.id);
      if (!mounted) return false;
      setState(() => _state = state);
      return true;
    } catch (error) {
      if (mounted) _showMessage(_messageFor(error));
      return false;
    }
  }

  Future<bool> _cancel() async {
    try {
      final state = await widget.repository.cancel();
      if (!mounted) return false;
      setState(() => _state = state);
      _showMessage('Subscription cancellation saved.');
      return true;
    } catch (error) {
      if (mounted) _showMessage(_messageFor(error));
      return false;
    }
  }

  String _messageFor(Object error) {
    if (error is ApiException) return error.message;
    return 'Could not update the subscription. Please try again.';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final fallback = const SubscriptionPlan(
      id: 'loading',
      name: 'Subscription',
      description: '',
      priceLabel: r'$0.00',
      isCurrent: true,
      isSelectable: false,
    );

    return ColoredBox(
      color: AppColors.background,
      child: ManageSubscriptionScreen(
        currentPlan: state?.currentPlan ?? fallback,
        availablePlans: state?.availablePlans ?? const [],
        isLoading: _loading,
        errorMessage: _error,
        onRetry: _load,
        onBack: widget.onBack,
        onConfirmChange: _changePlan,
        onCancelSubscription: state?.status == null ? null : _cancel,
        onTermsTap: widget.onTermsTap,
        onPrivacyPolicyTap: widget.onPrivacyPolicyTap,
      ),
    );
  }
}
