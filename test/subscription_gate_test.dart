import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/subscription/domain/subscription_state.dart';

void main() {
  test('auth alone does not confer paid-app access', () {
    final state = SubscriptionState.fromJson({
      'current_plan': {
        'id': 'free', 'name': 'Free', 'description': '',
        'price_label': r'$0.00',
      },
      'subscription': null,
      'has_access': false,
    });
    expect(state.hasAccess, false);
  });

  test('only backend has_access flag grants client navigation', () {
    final statusOnly = SubscriptionState.fromJson({
      'subscription': {'status': 'trialing', 'provider': 'stripe'},
    });
    expect(statusOnly.hasAccess, false);

    final verified = SubscriptionState.fromJson({
      'has_access': true,
      'subscription': {'status': 'trialing', 'provider': 'stripe'},
    });
    expect(verified.hasAccess, true);
  });
}
