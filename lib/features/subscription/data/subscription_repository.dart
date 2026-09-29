import '../../../core/network/api_client.dart';
import '../domain/subscription_state.dart';

class SubscriptionStartResult {
  const SubscriptionStartResult({
    required this.state,
    this.checkoutUrl,
  });

  final SubscriptionState state;
  final String? checkoutUrl;

  bool get requiresCheckout => checkoutUrl != null && checkoutUrl!.isNotEmpty;
}

class SubscriptionRepository {
  const SubscriptionRepository({required ApiClient apiClient})
    : this._(apiClient);

  const SubscriptionRepository._(this._apiClient);

  final ApiClient _apiClient;

  Future<SubscriptionState> fetch() async {
    final payload = await _apiClient.get('/subscription');
    return SubscriptionState.fromJson(payload);
  }

  Future<SubscriptionStartResult> startTrial(String planId) async {
    final payload = await _apiClient.post(
      '/subscription/start-trial',
      body: {'plan_id': _normalizePlanId(planId)},
    );

    return SubscriptionStartResult(
      state: SubscriptionState.fromJson(payload),
      checkoutUrl: payload['checkout_url']?.toString(),
    );
  }

  Future<SubscriptionState> changePlan(String planId) async {
    final payload = await _apiClient.put(
      '/subscription/plan',
      body: {'plan_id': _normalizePlanId(planId)},
    );
    return SubscriptionState.fromJson(payload);
  }

  Future<SubscriptionState> cancel() async {
    final payload = await _apiClient.post('/subscription/cancel');
    return SubscriptionState.fromJson(payload);
  }

  Object _normalizePlanId(String value) => int.tryParse(value) ?? value;
}
