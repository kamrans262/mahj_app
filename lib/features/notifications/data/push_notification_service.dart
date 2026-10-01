import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_repository.dart';
import 'notification_store.dart';

typedef PushNotificationTapHandler =
    Future<bool> Function(Map<String, dynamic> data);

class PushNotificationService {
  PushNotificationService({
    required NotificationRepository repository,
    required NotificationStore store,
  }) : _repository = repository,
       _store = store;

  final NotificationRepository _repository;
  final NotificationStore _store;

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  PushNotificationTapHandler? _tapHandler;
  Map<String, dynamic>? _pendingTapData;
  bool _initialized = false;
  bool _activated = false;

  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (!isSupported || _initialized) return;

    final messaging = FirebaseMessaging.instance;

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _pendingTapData = _messageData(initialMessage);
    }

    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      unawaited(_store.refreshUnreadCount());
    });

    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) {
        _pendingTapData = _messageData(message);
        unawaited(flushPendingTap());
      },
    );

    _tokenRefreshSubscription = messaging.onTokenRefresh.listen((token) {
      unawaited(_registerToken(token));
    });

    _initialized = true;
  }

  void setTapHandler(PushNotificationTapHandler handler) {
    _tapHandler = handler;
  }

  Future<void> activateForAuthenticatedUser() async {
    if (!isSupported) return;
    if (!_initialized) {
      await initialize();
    }

    if (!_activated) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      _activated = true;
    }

    await syncCurrentToken();
    await flushPendingTap();
  }

  Future<void> syncCurrentToken() async {
    if (!isSupported || !_initialized) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _registerToken(token);
    } catch (_) {
      // Token acquisition can temporarily fail while APNs/FCM is registering.
    }
  }

  Future<void> unregisterCurrentDevice() async {
    if (!isSupported || !_initialized) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _repository.unregisterDeviceToken(token);
    } catch (_) {
      // Logout must continue even when FCM is temporarily unavailable.
    }
  }

  Future<void> flushPendingTap() async {
    final data = _pendingTapData;
    final handler = _tapHandler;
    if (data == null || handler == null) return;

    final handled = await handler(data);
    if (handled) {
      _pendingTapData = null;
      unawaited(_store.refreshUnreadCount());
    }
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
  }

  Future<void> _registerToken(String token) async {
    if (!_activated) return;

    try {
      await _repository.registerDeviceToken(
        token: token,
        platform: defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
      );
    } catch (_) {
      // The authenticated session may not be ready yet. The next sync retries.
    }
  }

  Map<String, dynamic> _messageData(RemoteMessage message) {
    return <String, dynamic>{
      ...message.data,
      if (!message.data.containsKey('title') &&
          message.notification?.title != null)
        'title': message.notification!.title!,
      if (!message.data.containsKey('message') &&
          message.notification?.body != null)
        'message': message.notification!.body!,
    };
  }
}
