import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_asset_icon.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_surface_container.dart';
import '../../../core/widgets/app_text_field.dart';
import '../domain/privacy_safety_data.dart';

typedef PrivacySafetyUnblockCallback = Future<bool> Function(String playerId);
typedef PrivacySafetySearchCallback = Future<List<PrivacySafetyUser>> Function(
  String query,
);
typedef PrivacySafetyBlockCallback = Future<bool> Function(String playerId);
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
    this.onSearchUsers,
    this.onBlockUser,
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
  final PrivacySafetySearchCallback? onSearchUsers;
  final PrivacySafetyBlockCallback? onBlockUser;
  final PrivacySafetyPlayerTapCallback? onPlayerTap;
  final VoidCallback? onRetry;
  final bool isLoading;
  final String? errorMessage;

  @override
  State<PrivacySafetyScreen> createState() => _PrivacySafetyScreenState();
}

class _PrivacySafetyScreenState extends State<PrivacySafetyScreen> {
  late List<PrivacySafetyUser> _blockedUsers;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _unblockingIds = <String>{};
  final Set<String> _blockingIds = <String>{};
  List<PrivacySafetyUser> _searchResults = const <PrivacySafetyUser>[];
  Timer? _searchDebounce;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _blockedUsers = List<PrivacySafetyUser>.of(widget.blockedUsers);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
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

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();

    if (query.length < 2) {
      setState(() {
        _searchResults = const <PrivacySafetyUser>[];
        _searching = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_runSearch(query));
    });
  }

  Future<void> _runSearch(String query) async {
    final callback = widget.onSearchUsers;
    if (callback == null) return;

    setState(() => _searching = true);
    try {
      final results = await callback(query);
      if (!mounted || _searchController.text.trim() != query) return;
      setState(() => _searchResults = results);
    } catch (_) {
      if (mounted) _showMessage('Could not search players. Please try again.');
    } finally {
      if (mounted && _searchController.text.trim() == query) {
        setState(() => _searching = false);
      }
    }
  }

  Future<void> _handleBlock(PrivacySafetyUser player) async {
    if (_blockingIds.contains(player.id)) return;
    final callback = widget.onBlockUser;
    if (callback == null) return;

    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Block player confirmation',
      barrierColor: AppColors.confirmationBackdrop,
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final navigator = Navigator.of(dialogContext);
        return SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageHorizontal,
                vertical: AppSpacing.lg,
              ),
              child: AppConfirmationDialog(
                title: 'Block ${player.displayName}?',
                message:
                    'They will no longer be able to interact with you in eligible matches.',
                cancelLabel: 'Cancel',
                confirmLabel: 'Block',
                confirmVariant: AppConfirmationVariant.destructive,
                onCancel: () => navigator.pop(false),
                onConfirm: () => navigator.pop(true),
              ),
            ),
          ),
        );
      },
      transitionBuilder: _modalTransition,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _blockingIds.add(player.id));
    final success = await callback(player.id);
    if (!mounted) return;

    setState(() {
      _blockingIds.remove(player.id);
      if (success) {
        _searchResults = _searchResults
            .where((item) => item.id != player.id)
            .toList(growable: false);
        _blockedUsers = [
          player,
          ..._blockedUsers.where((item) => item.id != player.id),
        ];
      }
    });

    if (success) _showMessage('${player.displayName} blocked.');
  }

  Future<void> _handleUnblock(PrivacySafetyUser player) async {
    if (_unblockingIds.contains(player.id)) return;
    final callback = widget.onUnblock;
    if (callback == null) {
      _showMessage('Unblock is not connected yet.');
      return;
    }

    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Unblock player confirmation',
      barrierColor: AppColors.confirmationBackdrop,
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        var isLoading = false;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final navigator = Navigator.of(dialogContext);

            Future<void> confirm() async {
              if (isLoading) return;
              setDialogState(() => isLoading = true);

              setState(() => _unblockingIds.add(player.id));
              final succeeded = await callback(player.id);

              if (!mounted || !navigator.mounted) return;

              if (succeeded) {
                navigator.pop(true);
                return;
              }

              setState(() => _unblockingIds.remove(player.id));
              setDialogState(() => isLoading = false);
              _showMessage('Could not unblock ${player.displayName}.');
            }

            return PopScope(
              canPop: !isLoading,
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageHorizontal,
                      vertical: AppSpacing.lg,
                    ),
                    child: AppConfirmationDialog(
                      title: 'Unblock ${player.displayName}?',
                      message:
                          'This player will be able to see your eligible matches again.',
                      cancelLabel: 'Cancel',
                      confirmLabel: 'Unblock',
                      isLoading: isLoading,
                      onCancel: isLoading ? null : () => navigator.pop(false),
                      onConfirm: isLoading ? null : confirm,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: _modalTransition,
    );

    if (!mounted) return;
    setState(() => _unblockingIds.remove(player.id));

    if (confirmed == true) {
      setState(() {
        _blockedUsers.removeWhere((item) => item.id == player.id);
      });
      _showMessage('${player.displayName} unblocked.');
    }
  }

  Widget _modalTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
        child: child,
      ),
    );
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
          _SectionLabel(text: 'Find a Player to Block'),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: _searchController,
            hintText: 'Search by name, email or city',
            leadingIcon: Icons.search_rounded,
            textInputAction: TextInputAction.search,
            onChanged: _onSearchChanged,
            onFieldSubmitted: (value) {
              final query = value.trim();
              if (query.length >= 2) unawaited(_runSearch(query));
            },
          ),
          if (_searching) ...[
            const SizedBox(height: AppSpacing.sm),
            const Center(child: AppLoader(size: 20, strokeWidth: 2)),
          ] else if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _UserGroup(
              users: _searchResults,
              actionBuilder: (player) => _OutlineStatusAction(
                key: ValueKey('privacy-block-${player.id}'),
                label: 'Block',
                isLoading: _blockingIds.contains(player.id),
                onTap: () => _handleBlock(player),
              ),
              onPlayerTap: widget.onPlayerTap,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
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
