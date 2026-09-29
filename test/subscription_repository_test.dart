import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/core/network/api_client.dart';
import 'package:mahj_app/core/storage/token_store.dart';
import 'package:mahj_app/features/subscription/data/subscription_repository.dart';

class _MemoryTokenStore implements TokenStore {
  String? token = 'test-token';

  @override
  Future<void> clear() async => token = null;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async => this.token = token;
}

void main() {
  test('subscription repository parses live subscription state', () async {
    final client = MockClient((request) async {
      expect(request.headers['authorization'], 'Bearer test-token');
      expect(request.url.path, '/api/subscription');

      return http.Response(
        jsonEncode({
          'current_plan': {
            'id': '1',
            'name': 'Monthly Plan',
            'description': 'No charges for 14 days',
            'price_label': r'$9.99',
            'status_text': 'Trialing',
            'is_current': true,
            'is_selectable': false,
            'trial_days': 14,
          },
          'available_plans': [
            {
              'id': '1',
              'name': 'Monthly Plan',
              'description': 'No charges for 14 days',
              'price_label': r'$9.99',
              'is_current': true,
              'is_selectable': false,
              'trial_days': 14,
            },
          ],
          'subscription': {
            'status': 'trialing',
            'cancel_at_period_end': false,
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final api = ApiClient(
      baseUrl: 'https://example.com/api',
      tokenStore: _MemoryTokenStore(),
      httpClient: client,
    );
    final repository = SubscriptionRepository(apiClient: api);

    final state = await repository.fetch();

    expect(state.currentPlan.name, 'Monthly Plan');
    expect(state.currentPlan.trialDays, 14);
    expect(state.status, 'trialing');
    expect(state.availablePlans, hasLength(1));
  });
}
