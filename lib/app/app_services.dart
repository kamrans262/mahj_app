import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_store.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/chat/data/chat_repository.dart';
import '../features/home/data/home_preload_store.dart';
import '../features/home/data/location_repository.dart';
import '../features/home/data/match_discovery_store.dart';
import '../features/matches/data/match_repository.dart';
import '../features/notifications/data/notification_repository.dart';
import '../features/notifications/data/notification_store.dart';
import '../features/notifications/data/push_notification_service.dart';
import '../features/settings/data/privacy_safety_repository.dart';
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

  static final MatchRepository matchRepository = MatchRepository(
    apiClient: apiClient,
  );

  static final ChatRepository chatRepository = ChatRepository(
    apiClient: apiClient,
  );

  static final NotificationRepository notificationRepository =
      NotificationRepository(apiClient: apiClient);

  static final NotificationStore notificationStore = NotificationStore(
    repository: notificationRepository,
  );

  static final PushNotificationService pushNotificationService =
      PushNotificationService(
        repository: notificationRepository,
        store: notificationStore,
      );

  static final LocationRepository locationRepository = LocationRepository(
    apiClient: apiClient,
  );

  static final PrivacySafetyRepository privacySafetyRepository =
      PrivacySafetyRepository(apiClient: apiClient);

  static final MatchDiscoveryStore matchDiscoveryStore = MatchDiscoveryStore();

  static final HomePreloadStore homePreloadStore = HomePreloadStore(
    matchRepository: matchRepository,
    locationRepository: locationRepository,
    discoveryStore: matchDiscoveryStore,
  );
}
