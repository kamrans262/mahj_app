import 'subscription_plan.dart';

class SubscriptionState {
  const SubscriptionState({
    required this.currentPlan,
    required this.availablePlans,
    this.status,
    this.provider,
    this.cancelAtPeriodEnd = false,
    this.hasAccess = false,
    this.canStartTrial = true,
    this.trialExpired = false,
  });

  final SubscriptionPlan currentPlan;
  final List<SubscriptionPlan> availablePlans;
  final String? status;
  final String? provider;
  final bool cancelAtPeriodEnd;
  /// True only after the backend verifies the Stripe entitlement.
  final bool hasAccess;
  /// Only first-time accounts may start the 30-day Stripe trial.
  final bool canStartTrial;
  /// Used to label an expired trial without changing the approved layout.
  final bool trialExpired;

  factory SubscriptionState.fromJson(Map<String, dynamic> json) {
    final rawCurrent = json['current_plan'];
    final current = rawCurrent is Map<String, dynamic>
        ? SubscriptionPlan.fromJson(rawCurrent)
        : const SubscriptionPlan(
            id: 'free',
            name: 'Free',
            description: 'No active subscription',
            priceLabel: r'$0.00',
            statusText: 'Inactive',
            isCurrent: true,
            isSelectable: false,
            trialDays: 0,
          );

    final plans = <SubscriptionPlan>[];
    final rawPlans = json['available_plans'];
    if (rawPlans is List) {
      for (final item in rawPlans) {
        if (item is Map<String, dynamic>) {
          plans.add(SubscriptionPlan.fromJson(item));
        } else if (item is Map) {
          plans.add(
            SubscriptionPlan.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          );
        }
      }
    }

    final rawSubscription = json['subscription'];
    final subscription = rawSubscription is Map<String, dynamic>
        ? rawSubscription
        : null;

    final status = subscription?['status']?.toString();
    final rawTrialEnd = subscription?['trial_ends_at']?.toString();
    final trialEnd = rawTrialEnd == null ? null : DateTime.tryParse(rawTrialEnd);
    final hasAccess = json['has_access'] == true;

    return SubscriptionState(
      currentPlan: current,
      availablePlans: List.unmodifiable(plans),
      status: status,
      provider: subscription?['provider']?.toString(),
      cancelAtPeriodEnd: subscription?['cancel_at_period_end'] == true,
      hasAccess: hasAccess,
      canStartTrial: json['can_start_trial'] is bool
          ? json['can_start_trial'] == true
          : subscription == null,
      trialExpired: json['trial_expired'] == true ||
          (!hasAccess &&
              status == 'trialing' &&
              trialEnd != null &&
              !trialEnd.isAfter(DateTime.now())),
    );
  }
}
