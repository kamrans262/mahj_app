import 'package:flutter/material.dart';

import '../../../../app/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_asset_icon.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.greeting,
    required this.displayName,
    required this.subtitle,
    required this.notificationCount,
    required this.messageCount,
    super.key,
    this.onNotificationTap,
    this.onMessageTap,
  });

  final String greeting;
  final String displayName;
  final String subtitle;
  final int notificationCount;
  final int messageCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMessageTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$greeting, ',
                        style: AppTypography.homeGreeting,
                      ),
                      TextSpan(
                        text: displayName,
                        style: AppTypography.homeGreeting.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.homeSubtitle,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        HeaderActionButton(
          key: const ValueKey('home-header-notifications'),
          semanticsLabel: 'Notifications',
          assetPath: AppAssets.homeBellIcon,
          fallbackIcon: Icons.notifications_none,
          unreadCount: notificationCount,
          onTap: onNotificationTap,
        ),
        const SizedBox(width: AppSpacing.md),
        HeaderActionButton(
          key: const ValueKey('home-header-messages'),
          semanticsLabel: 'Messages',
          assetPath: AppAssets.homeMessageIcon,
          fallbackIcon: Icons.chat_bubble_outline,
          unreadCount: messageCount,
          onTap: onMessageTap,
        ),
      ],
    );
  }
}

class HeaderActionButton extends StatelessWidget {
  const HeaderActionButton({
    required this.semanticsLabel,
    required this.assetPath,
    required this.fallbackIcon,
    required this.unreadCount,
    super.key,
    this.onTap,
  });

  final String semanticsLabel;
  final String assetPath;
  final IconData fallbackIcon;
  final int unreadCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: SizedBox.square(
        dimension: 40,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Material(
                color: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.65),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: Center(
                    child: assetPath.isNotEmpty
                        ? AppAssetIcon(assetPath: assetPath, size: 24)
                        : Icon(
                            fallbackIcon,
                            size: 24,
                            color: AppColors.heading,
                          ),
                  ),
                ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: -3,
                top: -4,
                child: _UnreadBadge(count: unreadCount),
              ),
          ],
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFD92D20),
        shape: BoxShape.circle,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 1,
          color: Colors.white,
        ),
      ),
    );
  }
}
