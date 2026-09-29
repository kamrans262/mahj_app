import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_store.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/subscription/data/subscription_repository.dart';

abstract final class AppServices {
  static final TokenStore tokenStore = SecureTokenStore();

  static final ApiClient apiClient = ApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    tokenStore: tokenStore,
  );

  static final AuthRepository authRepository = AuthRepository(
    apiClient: apiClient,
    tokenStore: tokenStore,
  );

  static final SubscriptionRepository subscriptionRepository =
      SubscriptionRepository(apiClient: apiClient);
}
