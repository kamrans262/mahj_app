import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
    extends State<ConnectedManageSubscriptionScreen>
    with WidgetsBindingObserver {
  SubscriptionState? _state;
  String? _error;
  bool _loading = true;
  bool _waitingForCheckout = false;
  bool _refreshingCheckout = false;
  String? _pendingCheckoutSessionId;
  int _selectionRevision = 0;

  bool get _hasCurrentPaidSubscription {
    final state = _state;
    if (state == null ||
        !const {'active', 'trialing'}.contains(state.status)) {
      return false;
    }

    final currentPlanId = state.currentPlan.id.trim().toLowerCase();
    return currentPlanId.isNotEmpty && currentPlanId != 'free';
  }

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

  Future<bool> _startPayment(SubscriptionPlan plan) async {
    try {
      final result = await widget.repository.startPayment(plan.id);
      if (!mounted) return false;

      if (!result.requiresCheckout ||
          result.checkoutUrl == null ||
          result.checkoutSessionId == null) {
        _showMessage('Stripe checkout could not be started.');
        return false;
      }

      final checkoutUrl = Uri.tryParse(result.checkoutUrl!);
      if (checkoutUrl == null) {
        _showMessage('Stripe checkout could not be started.');
        return false;
      }

      final opened = await launchUrl(
        checkoutUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!opened || !mounted) {
        _showMessage('Stripe checkout could not be opened.');
        return false;
      }

      setState(() {
        _state = result.state;
        _waitingForCheckout = true;
        _pendingCheckoutSessionId = result.checkoutSessionId;
      });

      _showMessage('Complete the payment in Stripe, then return to Mahj.');
      return true;
    } catch (error) {
      if (mounted) _showMessage(_messageFor(error));
      return false;
    }
  }

  Future<void> _refreshAfterCheckout() async {
    if (_refreshingCheckout) return;
    _refreshingCheckout = true;

    try {
      final sessionId = _pendingCheckoutSessionId;
      SubscriptionState state;

      if (sessionId != null && sessionId.isNotEmpty) {
        state = await widget.repository.confirmCheckout(sessionId);
      } else {
        state = await widget.repository.fetch();
      }

      if (!mounted) return;

      final currentPlanId = state.currentPlan.id.trim().toLowerCase();
      final paymentSucceeded =
          const {'active', 'trialing'}.contains(state.status) &&
          currentPlanId.isNotEmpty &&
          currentPlanId != 'free';

      setState(() {
        _state = state;
        _waitingForCheckout = false;
        _pendingCheckoutSessionId = null;
        _selectionRevision++;
      });

      if (paymentSucceeded) {
        _showMessage('Monthly Plan activated.');
      } else {
        _showMessage('Payment was not completed.');
      }
    } catch (_) {
      try {
        final state = await widget.repository.fetch();
        if (!mounted) return;
        setState(() {
          _state = state;
          _waitingForCheckout = false;
          _pendingCheckoutSessionId = null;
          _selectionRevision++;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _waitingForCheckout = false;
          _pendingCheckoutSessionId = null;
          _selectionRevision++;
        });
      }
      if (mounted) {
        _showMessage('Payment was not completed.');
      }
    } finally {
      _refreshingCheckout = false;
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

  SubscriptionPlan _displayCurrentPlan(SubscriptionPlan fallback) {
    return _state?.currentPlan ?? fallback;
  }

  List<SubscriptionPlan> _displayAvailablePlans() {
    return _state?.availablePlans ?? const <SubscriptionPlan>[];
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

    final currentPlan = _displayCurrentPlan(fallback);
    final canCancel =
        _hasCurrentPaidSubscription &&
        state?.cancelAtPeriodEnd != true &&
        !_waitingForCheckout;

    return ColoredBox(
      color: AppColors.background,
      child: ManageSubscriptionScreen(
        key: ValueKey(
          'manage-subscription-${currentPlan.id}-$_selectionRevision',
        ),
        currentPlan: currentPlan,
        availablePlans: _displayAvailablePlans(),
        isLoading: _loading || _refreshingCheckout,
        errorMessage: _error,
        requiresPayment: !_hasCurrentPaidSubscription,
        onRetry: _load,
        onBack: widget.onBack,
        onConfirmPayment: _startPayment,
        onConfirmChange: _changePlan,
        onCancelSubscription: canCancel ? _cancel : null,
        onTermsTap: widget.onTermsTap,
        onPrivacyPolicyTap: widget.onPrivacyPolicyTap,
      ),
    );
  }
}
