import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mahj_app/core/network/api_client.dart';
import 'package:mahj_app/core/storage/token_store.dart';
import 'package:mahj_app/features/subscription/data/checkout_return_store.dart';
import 'package:mahj_app/features/subscription/data/subscription_repository.dart';
import 'package:mahj_app/features/subscription/domain/subscription_plan.dart';
import 'package:mahj_app/features/subscription/domain/subscription_state.dart';
import 'package:mahj_app/features/subscription/presentation/subscription_entry_screen.dart';

class _TokenStore implements TokenStore {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> read() async => 'test-token';

  @override
  Future<void> write(String token) async {}
}

final _trialPlan = SubscriptionPlan(
  id: '1',
  name: 'Monthly Plan',
  description: 'No charges for 14 days',
  priceLabel: r'$19.99',
  trialDays: 14,
);

final _inactive = SubscriptionState(
  currentPlan: const SubscriptionPlan(
    id: 'free',
    name: 'Free',
    description: 'No active subscription',
    priceLabel: r'$0.00',
    isCurrent: true,
    isSelectable: false,
  ),
  availablePlans: [_trialPlan],
);

final _trialing = SubscriptionState(
  currentPlan: _trialPlan.copyWith(
    isCurrent: true,
    isSelectable: false,
    statusText: 'Trialing',
  ),
  availablePlans: [_trialPlan],
  status: 'trialing',
  provider: 'stripe',
  hasAccess: true,
);

class _FakeSubscriptionRepository extends SubscriptionRepository {
  _FakeSubscriptionRepository()
      : super(apiClient: ApiClient(
          baseUrl: 'https://example.test/api',
          tokenStore: _TokenStore(),
          httpClient: MockClient((_) async => http.Response('{}', 200)),
        ));

  String? confirmedSessionId;

  @override
  Future<SubscriptionState> fetch() async => _inactive;

  @override
  Future<SubscriptionState> confirmCheckout(String sessionId) async {
    confirmedSessionId = sessionId;
    return _trialing;
  }
}

void main() {
  testWidgets('a Stripe return opens the app and confirms membership before Home',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final links = CheckoutReturnStore();
    addTearDown(links.dispose);
    final repository = _FakeSubscriptionRepository();
    var homeOpenings = 0;

    await tester.pumpWidget(MaterialApp(
      home: SubscriptionEntryScreen(
        repository: repository,
        checkoutReturnStore: links,
        onActivated: () async {
          homeOpenings++;
        },
      ),
    ));
    await tester.pumpAndSettle();

    expect(homeOpenings, 0);
    links.accept(
      Uri.parse('mahjaroundtown://billing/success?session_id=cs_test_paid123'),
    );
    await tester.pumpAndSettle();

    expect(repository.confirmedSessionId, 'cs_test_paid123');
    expect(homeOpenings, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a cold start preserves the checkout link through screen loading',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final links = CheckoutReturnStore();
    addTearDown(links.dispose);
    links.accept(
      Uri.parse('mahjaroundtown://billing/success?session_id=cs_live_recent'),
    );

    final repository = _FakeSubscriptionRepository();
    var homeOpenings = 0;
    await tester.pumpWidget(MaterialApp(
      home: SubscriptionEntryScreen(
        repository: repository,
        checkoutReturnStore: links,
        onActivated: () async {
          homeOpenings++;
        },
      ),
    ));
    await tester.pumpAndSettle();

    expect(repository.confirmedSessionId, 'cs_live_recent');
    expect(homeOpenings, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a canceled return does not grant access', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final links = CheckoutReturnStore();
    addTearDown(links.dispose);
    final repository = _FakeSubscriptionRepository();
    var homeOpenings = 0;
    await tester.pumpWidget(MaterialApp(
      home: SubscriptionEntryScreen(
        repository: repository,
        checkoutReturnStore: links,
        onActivated: () async {
          homeOpenings++;
        },
      ),
    ));
    await tester.pumpAndSettle();

    links.accept(Uri.parse('mahjaroundtown://billing/cancel'));
    await tester.pumpAndSettle();

    expect(repository.confirmedSessionId, isNull);
    expect(homeOpenings, 0);
    expect(tester.takeException(), isNull);
  });
}
