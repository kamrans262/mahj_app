import 'package:flutter/material.dart';

import '../../../../app/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_asset_icon.dart';
import '../../../home/presentation/home_date_time_formatter.dart';
import '../../domain/mahj_notification.dart';

class NotificationListItem extends StatelessWidget {
  const NotificationListItem({
    required this.notification,
    super.key,
    this.onTap,
  });

  final MahjNotification notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final timeLabel = HomeDateTimeFormatter.time(notification.createdAt);

    return Semantics(
      button: onTap != null,
      label:
          '${notification.title}. ${notification.message}. $timeLabel${notification.isRead ? '' : '. Unread'}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: Padding(
            key: const ValueKey('notification-content-padding'),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  key: const ValueKey('notification-icon-container'),
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.notificationIconSurface,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  child: const AppAssetIcon(
                    assetPath: AppAssets.notificationPlayersIcon,
                    size: 24,
                    color: AppColors.heading,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        key: const ValueKey('notification-title'),
                        style: AppTypography.homeMatchTitle16,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        notification.message,
                        key: const ValueKey('notification-message'),
                        style: AppTypography.homeMeta14,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    timeLabel,
                    maxLines: 1,
                    style: AppTypography.notificationTime10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
