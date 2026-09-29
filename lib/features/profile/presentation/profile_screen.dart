import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loader.dart';
import '../../home/presentation/widgets/home_header.dart';
import '../data/profile_preview_data.dart';
import '../domain/profile_data.dart';
import 'widgets/profile_menu_row.dart';
import 'widgets/profile_stat_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    this.data,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.onNotificationTap,
    this.onMessageTap,
    this.onSettingsTap,
    this.onFavoritesTap,
    this.onEditProfile,
  });

  final ProfileData? data;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onFavoritesTap;
  final VoidCallback? onEditProfile;

  ProfileData get _data => data ?? ProfilePreviewData.currentUser;

  @override
  Widget build(BuildContext context) {
    final profile = _data;

    return ColoredBox(
      color: AppColors.background,
      child: CustomScrollView(
        key: const ValueKey('profile-scroll-view'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverSafeArea(
            bottom: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.lg,
                AppSpacing.pageHorizontal,
                0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _ProfileHeader(
                    notificationCount: profile.unreadNotificationCount,
                    messageCount: profile.unreadMessageCount,
                    onNotificationTap: onNotificationTap,
                    onMessageTap: onMessageTap,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  if (isLoading)
                    const SizedBox(
                      height: 220,
                      child: Center(child: AppLoader()),
                    )
                  else if (errorMessage != null)
                    _ProfileStateMessage(
                      message: errorMessage!,
                      onRetry: onRetry,
                    )
                  else ...[
                    _ProfileIdentity(profile: profile),
                    const SizedBox(height: AppSpacing.xl),
                    _ProfileStats(profile: profile),
                    const SizedBox(height: AppSpacing.lg),
                    ProfileMenuRow(
                      key: const ValueKey('profile-settings-row'),
                      iconAsset: AppAssets.profileSettingsIcon,
                      label: 'Settings',
                      trailingAsset: AppAssets.profileForwardIcon,
                      onTap: onSettingsTap,
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    ProfileMenuRow(
                      key: const ValueKey('profile-favorites-row'),
                      iconAsset: AppAssets.profileFavoritesIcon,
                      label: 'Favorites',
                      trailingAsset: AppAssets.profileForwardIcon,
                      onTap: onFavoritesTap,
                    ),
                  ],
                ]),
              ),
            ),
          ),
          if (!isLoading && errorMessage == null)
            SliverFillRemaining(
              hasScrollBody: false,
              fillOverscroll: false,
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal,
                  AppSpacing.lg,
                  AppSpacing.pageHorizontal,
                  AppSpacing.lg,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: AppButton.primary(
                    key: const ValueKey('profile-edit-button'),
                    label: 'Edit Profile',
                    onPressed: onEditProfile ?? () {},
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xs)),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.notificationCount,
    required this.messageCount,
    this.onNotificationTap,
    this.onMessageTap,
  });

  final int notificationCount;
  final int messageCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMessageTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'My Profile',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.homeGreeting,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        HeaderActionButton(
          key: const ValueKey('profile-header-notifications'),
          semanticsLabel: 'Notifications',
          assetPath: AppAssets.homeBellIcon,
          fallbackIcon: Icons.notifications_none,
          unreadCount: notificationCount,
          onTap: onNotificationTap,
        ),
        const SizedBox(width: AppSpacing.md),
        HeaderActionButton(
          key: const ValueKey('profile-header-messages'),
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

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({required this.profile});

  final ProfileData profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppAvatar(
          key: const ValueKey('profile-avatar'),
          fallbackAsset: profile.avatarAsset,
          imageUrl: profile.avatarUrl,
          size: 60,
        ),
        const SizedBox(height: AppSpacing.iconGap),
        Text(
          profile.name,
          textAlign: TextAlign.center,
          style: AppTypography.homeMatchTitle18,
        ),
        const SizedBox(height: AppSpacing.micro),
        Text(
          profile.email,
          textAlign: TextAlign.center,
          softWrap: true,
          style: AppTypography.homeMeta12,
        ),
        const SizedBox(height: AppSpacing.micro),
        Text(
          profile.addressLine,
          textAlign: TextAlign.center,
          softWrap: true,
          style: AppTypography.homeMeta12,
        ),
      ],
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({required this.profile});

  final ProfileData profile;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 310 || textScale > 1.45;
        final upcoming = ProfileStatCard(
          key: const ValueKey('profile-upcoming-stat'),
          label: 'Upcoming matches',
          value: profile.upcomingMatchCount,
        );
        final completed = ProfileStatCard(
          key: const ValueKey('profile-completed-stat'),
          label: 'Completed matches',
          value: profile.completedMatchCount,
        );

        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              upcoming,
              const SizedBox(height: AppSpacing.iconGap),
              completed,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: upcoming),
            const SizedBox(width: AppSpacing.iconGap),
            Expanded(child: completed),
          ],
        );
      },
    );
  }
}

class _ProfileStateMessage extends StatelessWidget {
  const _ProfileStateMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body14,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: onRetry,
                child: Text('Retry', style: AppTypography.action14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
