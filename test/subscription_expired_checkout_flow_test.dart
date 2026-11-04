import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mahj_app/app/theme/app_theme.dart';
import 'package:mahj_app/core/network/api_client.dart';
import 'package:mahj_app/core/storage/token_store.dart';
import 'package:mahj_app/features/subscription/data/subscription_repository.dart';
import 'package:mahj_app/features/subscription/presentation/subscription_entry_screen.dart';

Map<String, dynamic> _subscriptionState({
  required bool eligibleForTrial,
  bool hasAccess = false,
}) => {
  'current_plan': hasAccess
      ? {
          'id': '1',
          'name': 'Monthly Plan',
          'description': 'Monthly membership',
          'price_label': r'$19.99',
          'is_current': true,
          'is_selectable': false,
          'trial_days': 30,
        }
      : {
          'id': 'free',
          'name': 'Free',
          'description': 'No active subscription',
          'price_label': r'$0.00',
          'is_current': true,
          'is_selectable': false,
          'trial_days': 0,
        },
  'available_plans': [
    {
      'id': '1',
      'name': 'Monthly Plan',
      'description': 'No charges for 30 days',
      'price_label': r'$19.99',
      'is_current': hasAccess,
      'is_selectable': !hasAccess,
      'trial_days': 30,
    },
  ],
  'subscription': eligibleForTrial
      ? null
      : {
          'status': hasAccess ? 'active' : 'trialing',
          'provider': 'stripe',
          'trial_ends_at': '2026-10-01T00:00:00Z',
        },
  'has_access': hasAccess,
  'can_start_trial': eligibleForTrial,
  'trial_expired': !eligibleForTrial && !hasAccess,
};

void _screenSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('expired trial Pay Now uses paid checkout with no trial request', (
    tester,
  ) async {
    _screenSize(tester);
    final methods = <String>[];
    Uri? openedCheckout;
    final mock = MockClient((request) async {
      methods.add('${request.method} ${request.url.path}');
      if (request.method == 'GET') {
        return http.Response(jsonEncode(_subscriptionState(eligibleForTrial: false)), 200);
      }
      if (request.url.path == '/api/subscription/start-payment') {
        return http.Response(jsonEncode({
          ..._subscriptionState(eligibleForTrial: false),
          'requires_checkout': true,
          'checkout_session_id': 'cs_test_after_trial',
          'checkout_url': 'https://checkout.stripe.com/c/pay/cs_test_after_trial',
        }), 201);
      }
      return http.Response('{"message":"Unexpected endpoint"}', 500);
    });
    final repository = SubscriptionRepository(
      apiClient: ApiClient(
        baseUrl: 'https://example.test/api',
        tokenStore: SecureTokenStore(useMemoryOnly: true),
        httpClient: mock,
      ),
    );

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: SubscriptionEntryScreen(
        repository: repository,
        checkoutLauncher: (url) async {
          openedCheckout = url;
          return true;
        },
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Free Trial Expired'), findsOneWidget);
    expect(find.text('Pay Now'), findsOneWidget);
    expect(find.text('No charges for 30 days'), findsNothing);
    expect(find.text('Secure payment through Stripe'), findsOneWidget);

    final button = find.byKey(const ValueKey('pay-now-button'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(methods.where((method) => method == 'POST /api/subscription/start-payment'), hasLength(1));
    expect(methods.any((method) => method == 'POST /api/subscription/start-trial'), isFalse);
    expect(openedCheckout?.host, 'checkout.stripe.com');
    expect(tester.takeException(), isNull);
  });

  testWidgets('first-time subscriber continues to use 30-day trial Stripe checkout', (
    tester,
  ) async {
    _screenSize(tester);
    final methods = <String>[];
    final mock = MockClient((request) async {
      methods.add('${request.method} ${request.url.path}');
      if (request.method == 'GET') {
        return http.Response(jsonEncode(_subscriptionState(eligibleForTrial: true)), 200);
      }
      return http.Response(jsonEncode({
        ..._subscriptionState(eligibleForTrial: true),
        'requires_checkout': true,
        'checkout_session_id': 'cs_test_trial',
        'checkout_url': 'https://checkout.stripe.com/c/pay/cs_test_trial',
      }), 201);
    });
    var opened = false;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: SubscriptionEntryScreen(
        repository: SubscriptionRepository(
          apiClient: ApiClient(
            baseUrl: 'https://example.test/api',
            tokenStore: SecureTokenStore(useMemoryOnly: true),
            httpClient: mock,
          ),
        ),
        checkoutLauncher: (_) async {
          opened = true;
          return true;
        },
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Start your 30 day free trial'), findsOneWidget);
    final button = find.byKey(const ValueKey('start-free-trial-button'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(methods.where((method) => method == 'POST /api/subscription/start-trial'), hasLength(1));
    expect(methods.any((method) => method == 'POST /api/subscription/start-payment'), isFalse);
    expect(opened, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('freshly active Stripe subscription opens Home instead of paying twice', (
    tester,
  ) async {
    _screenSize(tester);
    var getCount = 0;
    var posted = false;
    var homeOpened = false;
    final mock = MockClient((request) async {
      if (request.method == 'GET') {
        getCount++;
        return http.Response(
          jsonEncode(_subscriptionState(
            eligibleForTrial: false,
            hasAccess: getCount > 1,
          )),
          200,
        );
      }
      posted = true;
      return http.Response('{"message":"Should not be called"}', 500);
    });
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: SubscriptionEntryScreen(
        repository: SubscriptionRepository(
          apiClient: ApiClient(
            baseUrl: 'https://example.test/api',
            tokenStore: SecureTokenStore(useMemoryOnly: true),
            httpClient: mock,
          ),
        ),
        onActivated: () async => homeOpened = true,
        checkoutLauncher: (_) async {
          fail('Stripe must not open for already active subscription');
          return false;
        },
      ),
    ));
    await tester.pumpAndSettle();

    final button = find.byKey(const ValueKey('pay-now-button'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(homeOpened, isTrue);
    expect(posted, isFalse);
    expect(tester.takeException(), isNull);
  });
}
