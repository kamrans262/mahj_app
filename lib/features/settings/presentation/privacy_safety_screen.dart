import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_asset_icon.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_surface_container.dart';
import '../domain/privacy_safety_data.dart';

typedef PrivacySafetyUnblockCallback = Future<bool> Function(String playerId);
typedef PrivacySafetyPlayerTapCallback = void Function(
  PrivacySafetyUser player,
);

class PrivacySafetyScreen extends StatefulWidget {
  const PrivacySafetyScreen({
    required this.blockedUsers,
    required this.rules,
    required this.reportHistory,
    super.key,
    this.onBack,
    this.onUnblock,
    this.onPlayerTap,
    this.onRetry,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<PrivacySafetyUser> blockedUsers;
  final List<PrivacySafetyRule> rules;
  final List<PrivacyReportHistoryEntry> reportHistory;
  final VoidCallback? onBack;
  final PrivacySafetyUnblockCallback? onUnblock;
  final PrivacySafetyPlayerTapCallback? onPlayerTap;
  final VoidCallback? onRetry;
  final bool isLoading;
  final String? errorMessage;

  @override
  State<PrivacySafetyScreen> createState() => _PrivacySafetyScreenState();
}

class _PrivacySafetyScreenState extends State<PrivacySafetyScreen> {
  late List<PrivacySafetyUser> _blockedUsers;
  final Set<String> _unblockingIds = <String>{};

  @override
  void initState() {
    super.initState();
    _blockedUsers = List<PrivacySafetyUser>.of(widget.blockedUsers);
  }

  @override
  void didUpdateWidget(covariant PrivacySafetyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.blockedUsers, widget.blockedUsers) &&
        oldWidget.blockedUsers != widget.blockedUsers) {
      _blockedUsers = List<PrivacySafetyUser>.of(widget.blockedUsers);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleUnblock(PrivacySafetyUser player) async {
    if (_unblockingIds.contains(player.id)) return;
    final callback = widget.onUnblock;
    if (callback == null) {
      _showMessage('Unblock is not connected yet.');
      return;
    }

    setState(() => _unblockingIds.add(player.id));
    try {
      final succeeded = await callback(player.id);
      if (!mounted) return;
      if (succeeded) {
        setState(() {
          _blockedUsers.removeWhere((item) => item.id == player.id);
        });
      } else {
        _showMessage('Could not unblock ${player.displayName}.');
      }
    } finally {
      if (mounted) {
        setState(() => _unblockingIds.remove(player.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('privacy-safety-screen'),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.lg,
                AppSpacing.pageHorizontal,
                0,
              ),
              child: AppCenteredPageHeader(
                title: 'Privacy & Safety',
                onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (widget.isLoading) {
      return const Center(child: AppLoader());
    }

    final error = widget.errorMessage?.trim();
    if (error != null && error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error,
                textAlign: TextAlign.center,
                style: AppTypography.homeMeta14,
              ),
              if (widget.onRetry != null) ...[
                const SizedBox(height: AppSpacing.lg),
                AppButton.compactSecondary(
                  label: 'Retry',
                  onPressed: widget.onRetry,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      key: const ValueKey('privacy-safety-scroll-view'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        25,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionLabel(text: 'Blocked Users'),
          const SizedBox(height: AppSpacing.sm),
          _blockedUsers.isEmpty
              ? const _EmptySection(message: 'No blocked users')
              : _UserGroup(
                  users: _blockedUsers,
                  actionBuilder: (player) => _OutlineStatusAction(
                    key: ValueKey('privacy-unblock-${player.id}'),
                    label: 'Unblock',
                    isLoading: _unblockingIds.contains(player.id),
                    onTap: () => _handleUnblock(player),
                  ),
                  onPlayerTap: widget.onPlayerTap,
                ),
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel(text: 'Rules to Follow'),
          const SizedBox(height: AppSpacing.sm),
          _RulesGroup(rules: widget.rules),
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel(text: 'Report History'),
          const SizedBox(height: AppSpacing.sm),
          widget.reportHistory.isEmpty
              ? const _EmptySection(message: 'No report history')
              : _ReportHistoryGroup(
                  entries: widget.reportHistory,
                  onPlayerTap: widget.onPlayerTap,
                ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.homeMeta14);
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceContainer(
      minHeight: 0,
      backgroundColor: AppColors.background,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTypography.homeMeta14,
      ),
    );
  }
}

class _UserGroup extends StatelessWidget {
  const _UserGroup({
    required this.users,
    required this.actionBuilder,
    this.onPlayerTap,
  });

  final List<PrivacySafetyUser> users;
  final Widget Function(PrivacySafetyUser player) actionBuilder;
  final PrivacySafetyPlayerTapCallback? onPlayerTap;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceContainer(
      key: const ValueKey('privacy-blocked-users-container'),
      minHeight: 0,
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < users.length; index++) ...[
            _SafetyUserRow(
              player: users[index],
              trailing: actionBuilder(users[index]),
              onPlayerTap: onPlayerTap,
            ),
            if (index < users.length - 1)
              const Divider(height: 1, color: AppColors.divider),
          ],
        ],
      ),
    );
  }
}

class _SafetyUserRow extends StatelessWidget {
  const _SafetyUserRow({
    required this.player,
    required this.trailing,
    this.onPlayerTap,
  });

  final PrivacySafetyUser player;
  final Widget trailing;
  final PrivacySafetyPlayerTapCallback? onPlayerTap;

  @override
  Widget build(BuildContext context) {
    final summary = Row(
      children: [
        AppAvatar(
          fallbackAsset: player.avatarAsset,
          imageUrl: player.avatarUrl,
          size: 40,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                player.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.homeMatchTitle16,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                player.secondaryLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.homeMeta14,
              ),
            ],
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: onPlayerTap == null
                ? summary
                : Semantics(
                    button: true,
                    label: 'Open ${player.displayName} profile',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.control),
                      onTap: () => onPlayerTap!(player),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: summary,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),
          trailing,
        ],
      ),
    );
  }
}

class _OutlineStatusAction extends StatelessWidget {
  const _OutlineStatusAction({
    required this.label,
    super.key,
    this.onTap,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !isLoading;
    return Semantics(
      button: onTap != null,
      enabled: enabled,
      label: label,
      child: Material(
        color: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.40)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 84, minHeight: 42),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: isLoading
                    ? const AppLoader(size: 18, strokeWidth: 2)
                    : Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.homeMeta14,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RulesGroup extends StatelessWidget {
  const _RulesGroup({required this.rules});

  final List<PrivacySafetyRule> rules;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceContainer(
      key: const ValueKey('privacy-rules-container'),
      minHeight: 0,
      backgroundColor: AppColors.background,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < rules.length; index++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppAssetIcon(
                  assetPath: AppAssets.approveIcon,
                  size: 26,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.micro),
                    child: Text(
                      rules[index].label,
                      style: AppTypography.body16.copyWith(
                        color: AppColors.heading,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (index < rules.length - 1) const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _ReportHistoryGroup extends StatelessWidget {
  const _ReportHistoryGroup({required this.entries, this.onPlayerTap});

  final List<PrivacyReportHistoryEntry> entries;
  final PrivacySafetyPlayerTapCallback? onPlayerTap;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceContainer(
      key: const ValueKey('privacy-report-history-container'),
      minHeight: 0,
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < entries.length; index++) ...[
            _SafetyUserRow(
              player: entries[index].player,
              trailing: _OutlineStatusAction(label: entries[index].statusLabel),
              onPlayerTap: onPlayerTap,
            ),
            if (index < entries.length - 1)
              const Divider(height: 1, color: AppColors.divider),
          ],
        ],
      ),
    );
  }
}
