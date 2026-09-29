import 'subscription_plan.dart';

class SubscriptionState {
  const SubscriptionState({
    required this.currentPlan,
    required this.availablePlans,
    this.status,
    this.cancelAtPeriodEnd = false,
  });

  final SubscriptionPlan currentPlan;
  final List<SubscriptionPlan> availablePlans;
  final String? status;
  final bool cancelAtPeriodEnd;

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

    return SubscriptionState(
      currentPlan: current,
      availablePlans: List.unmodifiable(plans),
      status: subscription?['status']?.toString(),
      cancelAtPeriodEnd: subscription?['cancel_at_period_end'] == true,
    );
  }
}
