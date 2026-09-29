import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_loader.dart';
import '../data/notifications_preview_data.dart';
import '../domain/mahj_notification.dart';
import 'widgets/notification_list_item.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    this.notifications,
    this.isLoading = false,
    this.errorMessage,
    this.onBack,
    this.onNotificationTap,
    this.onReadStateChanged,
    this.onRetry,
    this.onRefresh,
  });

  final List<MahjNotification>? notifications;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onBack;
  final Future<void> Function(MahjNotification notification)? onNotificationTap;
  final ValueChanged<List<MahjNotification>>? onReadStateChanged;
  final VoidCallback? onRetry;
  final Future<void> Function()? onRefresh;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<MahjNotification> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = List<MahjNotification>.of(
      widget.notifications ?? NotificationsPreviewData.create(),
    );
  }

  @override
  void didUpdateWidget(covariant NotificationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notifications != widget.notifications &&
        widget.notifications != null) {
      _notifications = List<MahjNotification>.of(widget.notifications!);
    }
  }

  Future<void> _openNotification(int index) async {
    final current = _notifications[index];
    final opened = current.isRead ? current : current.copyWith(isRead: true);

    if (!current.isRead) {
      setState(() => _notifications[index] = opened);
      widget.onReadStateChanged?.call(
        List<MahjNotification>.unmodifiable(_notifications),
      );
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

    final list = ListView.separated(
      key: const ValueKey('notifications-list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      itemCount: _notifications.length,
      separatorBuilder: (_, _) => const _NotificationSeparator(),
      itemBuilder: (context, index) {
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
