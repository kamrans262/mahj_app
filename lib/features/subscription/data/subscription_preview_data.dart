import '../domain/subscription_plan.dart';

abstract final class SubscriptionPreviewData {
  static const currentPlan = SubscriptionPlan(
    id: 'premium-current',
    name: 'Premium',
    description: 'Current membership',
    priceLabel: r'$19.99',
    renewalText: 'Renews on May 25, 2026',
    statusText: 'Active',
    infoText: 'You won’t be charged until the trial ends',
    isCurrent: true,
    isSelectable: false,
  );

  static const availablePlans = <SubscriptionPlan>[
    SubscriptionPlan(
      id: 'monthly',
      name: 'Monthly Plan',
      description: 'No charges for 14 days',
      priceLabel: r'$19.99',
      infoText: 'You won’t be charged until the trial ends',
    ),
  ];
}
