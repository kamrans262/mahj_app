import 'dart:async';

import 'package:flutter/material.dart';

import '../data/notification_store.dart';
import '../domain/mahj_notification.dart';
import 'notifications_screen.dart';

class ConnectedNotificationsScreen extends StatefulWidget {
  const ConnectedNotificationsScreen({
    required this.store,
    required this.onNotificationTap,
    super.key,
    this.onBack,
  });

  final NotificationStore store;
  final Future<void> Function(MahjNotification notification) onNotificationTap;
  final VoidCallback? onBack;

  @override
  State<ConnectedNotificationsScreen> createState() =>
      _ConnectedNotificationsScreenState();
}

class _ConnectedNotificationsScreenState
    extends State<ConnectedNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(widget.store.refresh());
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        return NotificationsScreen(
          notifications: widget.store.notifications,
          isLoading: widget.store.isLoading,
          isLoadingMore: widget.store.isLoadingMore,
          hasMore: widget.store.hasMore,
          errorMessage: widget.store.errorMessage,
          onBack: widget.onBack,
          onMarkRead: widget.store.markRead,
          onNotificationTap: widget.onNotificationTap,
          onRetry: () {
            unawaited(widget.store.refresh());
          },
          onRefresh: widget.store.refresh,
          onLoadMore: widget.store.loadMore,
        );
      },
    );
  }
}
