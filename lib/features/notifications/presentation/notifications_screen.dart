import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_loader.dart';
import '../data/notifications_preview_data.dart';
import '../domain/mahj_notification.dart';
import 'widgets/notification_list_item.dart';

typedef NotificationMarkReadCallback = Future<MahjNotification> Function(
  MahjNotification notification,
);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    this.notifications,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.errorMessage,
    this.onBack,
    this.onNotificationTap,
    this.onMarkRead,
    this.onReadStateChanged,
    this.onRetry,
    this.onRefresh,
    this.onLoadMore,
  });

  final List<MahjNotification>? notifications;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final VoidCallback? onBack;
  final Future<void> Function(MahjNotification notification)? onNotificationTap;
  final NotificationMarkReadCallback? onMarkRead;
  final ValueChanged<List<MahjNotification>>? onReadStateChanged;
  final VoidCallback? onRetry;
  final Future<void> Function()? onRefresh;
  final Future<void> Function()? onLoadMore;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  late List<MahjNotification> _notifications;
  bool _requestingMore = false;

  @override
  void initState() {
    super.initState();
    _notifications = List<MahjNotification>.of(
      widget.notifications ?? NotificationsPreviewData.create(),
    );
    _scrollController.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(covariant NotificationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notifications != widget.notifications &&
        widget.notifications != null) {
      _notifications = List<MahjNotification>.of(widget.notifications!);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 180 ||
        !widget.hasMore ||
        widget.isLoadingMore ||
        _requestingMore ||
        widget.onLoadMore == null) {
      return;
    }

    _loadMore();
  }

  Future<void> _loadMore() async {
    final callback = widget.onLoadMore;
    if (callback == null ||
        _requestingMore ||
        widget.isLoadingMore ||
        !widget.hasMore) {
      return;
    }

    _requestingMore = true;
    try {
      await callback();
    } finally {
      _requestingMore = false;
    }
  }

  Future<void> _openNotification(int index) async {
    final current = _notifications[index];
    var opened = current;

    if (!current.isRead) {
      final markRead = widget.onMarkRead;
      if (markRead != null) {
        try {
          opened = await markRead(current);
        } catch (_) {
          opened = current;
        }
      } else {
        opened = current.copyWith(isRead: true);
      }

      if (opened.isRead && mounted) {
        setState(() => _notifications[index] = opened);
        widget.onReadStateChanged?.call(
          List<MahjNotification>.unmodifiable(_notifications),
        );
      }
    }

    final callback = widget.onNotificationTap;
    if (callback != null) {
      await callback(opened);
    }
  }

  Widget _buildStateBody() {
    if (widget.isLoading && _notifications.isEmpty) {
      return const Center(child: AppLoader());
    }

    final errorMessage = widget.errorMessage;
    if (errorMessage != null && _notifications.isEmpty) {
      return _NotificationStateMessage(
        message: errorMessage,
        actionLabel: widget.onRetry == null ? null : 'Retry',
        onAction: widget.onRetry,
      );
    }

    if (_notifications.isEmpty) {
      return const _NotificationStateMessage(message: 'No notifications yet');
    }

    final itemCount = _notifications.length + (widget.isLoadingMore ? 1 : 0);
    final list = ListView.separated(
      key: const ValueKey('notifications-list'),
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const _NotificationSeparator(),
      itemBuilder: (context, index) {
        if (index >= _notifications.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(child: AppLoader()),
          );
        }

        final notification = _notifications[index];
        return NotificationListItem(
          key: ValueKey('notification-item-${notification.id}'),
          notification: notification,
          onTap: () => _openNotification(index),
        );
      },
    );

    final refresh = widget.onRefresh;
    if (refresh == null) return list;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: refresh,
      child: list,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('notifications-screen'),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
          child: Column(
            children: [
              AppCenteredPageHeader(
                title: 'Notifications',
                onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(child: _buildStateBody()),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationSeparator extends StatelessWidget {
  const _NotificationSeparator();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.divider);
  }
}

class _NotificationStateMessage extends StatelessWidget {
  const _NotificationStateMessage({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body14,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!, style: AppTypography.action14),
            ),
          ],
        ],
      ),
    );
  }
}
