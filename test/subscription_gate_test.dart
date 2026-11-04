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
  test('expired trial and past-due Stripe state require paid checkout', () {
    for (final status in const ['trialing', 'past_due', 'canceled']) {
      final state = SubscriptionState.fromJson({
        'subscription': {
          'status': status,
          'provider': 'stripe',
          'trial_ends_at': '2026-10-01T00:00:00Z',
        },
        'has_access': false,
        'can_start_trial': false,
        'trial_expired': true,
      });

      expect(state.canStartTrial, isFalse);
      expect(state.trialExpired, isTrue);
      expect(state.hasAccess, isFalse);
    }
  });

  test('first-time account remains eligible for 30-day trial', () {
    final state = SubscriptionState.fromJson({
      'subscription': null,
      'has_access': false,
      'can_start_trial': true,
      'trial_expired': false,
    });

    expect(state.canStartTrial, isTrue);
    expect(state.trialExpired, isFalse);
  });

}
