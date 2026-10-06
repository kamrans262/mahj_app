import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_responsive_action_pair.dart';
import '../../../core/widgets/app_surface_container.dart';
import '../../home/domain/home_match.dart';
import '../../home/presentation/widgets/home_header.dart';
import '../../home/presentation/widgets/match_card.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../../matches/domain/match_report.dart';
import '../../matches/presentation/widgets/report_match_dialog.dart';
import '../data/player_action_reasons.dart';
import '../domain/player_profile_data.dart';
import 'widgets/block_player_dialog.dart';

typedef PlayerProfileReportCallback = Future<bool> Function(
  PlayerReportRequest request,
);
typedef PlayerProfileBlockCallback = Future<bool> Function(
  PlayerBlockRequest request,
);
typedef PlayerProfileFavoriteStatusCallback = Future<bool> Function(
  String playerId,
);
typedef PlayerProfileFavoriteToggleCallback = Future<bool> Function(
  String playerId,
  bool favorite,
);

class PlayerProfileScreen extends StatefulWidget {
  const PlayerProfileScreen({
    required this.player,
    super.key,
    this.notificationCount = 0,
    this.messageCount = 0,
    this.isLoading = false,
    this.errorMessage,
    this.mutualGamesLoading = false,
    this.mutualGamesError,
    this.onRetry,
    this.onNotificationTap,
    this.onMessageTap,
    this.onViewAllMutualGames,
    this.onMutualGameTap,
    this.onSendInvite,
    this.onSubmitReport,
    this.onSubmitBlock,
    this.onLoadFavorite,
    this.onSetFavorite,
  });

  final PlayerProfileData player;
  final int notificationCount;
  final int messageCount;
  final bool isLoading;
  final String? errorMessage;
  final bool mutualGamesLoading;
  final String? mutualGamesError;
  final VoidCallback? onRetry;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onViewAllMutualGames;
  final ValueChanged<HomeMatch>? onMutualGameTap;
  final VoidCallback? onSendInvite;
  final PlayerProfileReportCallback? onSubmitReport;
  final PlayerProfileBlockCallback? onSubmitBlock;
  final PlayerProfileFavoriteStatusCallback? onLoadFavorite;
  final PlayerProfileFavoriteToggleCallback? onSetFavorite;

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  bool _isReportDialogOpen = false;
  bool _isBlockDialogOpen = false;
  bool _reportRequestInFlight = false;
  bool _blockRequestInFlight = false;
  bool _isBlocked = false;
  bool _isFavorite = false;
  bool _favoriteLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final callback = widget.onLoadFavorite;
    if (callback == null) return;

    setState(() => _favoriteLoading = true);
    try {
      final favorite = await callback(widget.player.id);
      if (!mounted) return;
      setState(() => _isFavorite = favorite);
    } catch (_) {
      // Keep the profile usable if favorite status cannot be loaded.
    } finally {
      if (mounted) setState(() => _favoriteLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteLoading || _isBlocked) return;

    final callback = widget.onSetFavorite;
    if (callback == null) {
      _showMessage('Player favorites are not connected yet.');
      return;
    }

    final next = !_isFavorite;
    setState(() => _favoriteLoading = true);
    try {
      final saved = await callback(widget.player.id, next);
      if (!mounted) return;
      setState(() => _isFavorite = saved);
      _showMessage(
        saved ? 'Player added to favorites' : 'Player removed from favorites',
      );
    } catch (_) {
      if (mounted) {
        _showMessage('Could not update favorites. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _favoriteLoading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _submitReport(ReportReason reason, String notes) async {
    if (_reportRequestInFlight) return false;

    final callback = widget.onSubmitReport;
    if (callback == null) {
      _showMessage('Player reporting is not connected yet.');
      return false;
    }

    _reportRequestInFlight = true;
    try {
      return await callback(
        PlayerReportRequest(
          playerId: widget.player.id,
          reasonId: reason.id,
          notes: notes,
        ),
      );
    } finally {
      _reportRequestInFlight = false;
    }
  }

  Future<bool> _submitBlock(ReportReason reason) async {
    if (_blockRequestInFlight) return false;

    final callback = widget.onSubmitBlock;
    if (callback == null) {
      _showMessage('Player blocking is not connected yet.');
      return false;
    }

    _blockRequestInFlight = true;
    try {
      return await callback(
        PlayerBlockRequest(playerId: widget.player.id, reasonId: reason.id),
      );
    } finally {
      _blockRequestInFlight = false;
    }
  }

  Future<void> _showReportDialog() async {
    if (_isReportDialogOpen || !widget.player.canReport) return;
    _isReportDialogOpen = true;

    try {
      final submitted = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Report player',
        barrierColor: AppColors.confirmationBackdrop,
        transitionDuration: const Duration(milliseconds: 160),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          final navigator = Navigator.of(dialogContext);
          final mediaQuery = MediaQuery.of(dialogContext);

          return SafeArea(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pageHorizontal,
                    vertical: AppSpacing.lg,
                  ),
                  child: ReportMatchDialog(
                    hostName: widget.player.name,
                    reasons: playerReportReasons,
                    onCancel: () => navigator.pop(false),
                    onSubmit: _submitReport,
                    onSuccess: () => navigator.pop(true),
                  ),
                ),
              ),
            ),
          );
        },
        transitionBuilder: _modalTransition,
      );

      if (submitted == true) {
        _showMessage('Report submitted');
      }
    } finally {
      _isReportDialogOpen = false;
    }
  }

  Future<void> _showBlockDialog() async {
    if (_isBlockDialogOpen || !widget.player.canBlock || _isBlocked) return;
    _isBlockDialogOpen = true;

    try {
      final blocked = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Block player',
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
                child: BlockPlayerDialog(
                  playerName: widget.player.name,
                  reasons: playerBlockReasons,
                  onCancel: () => navigator.pop(false),
                  onSubmit: _submitBlock,
                  onSuccess: () => navigator.pop(true),
                ),
              ),
            ),
          );
        },
        transitionBuilder: _modalTransition,
      );

      if (blocked == true) {
        setState(() => _isBlocked = true);
        _showMessage('Player blocked');
      }
    } finally {
      _isBlockDialogOpen = false;
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

  void _sendInvite() {
    if (!widget.player.canInvite || _isBlocked) return;
    final callback = widget.onSendInvite;
    if (callback == null) {
      _showMessage('Invite flow is not connected for this player yet.');
      return;
    }
    callback();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('player-profile-screen'),
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        key: const ValueKey('player-profile-scroll-view'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverSafeArea(
            sliver: SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.lg,
                AppSpacing.pageHorizontal,
                AppSpacing.lg,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _PlayerProfileHeader(
                    notificationCount: widget.notificationCount,
                    messageCount: widget.messageCount,
                    onNotificationTap: widget.onNotificationTap,
                    onMessageTap: widget.onMessageTap,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  if (widget.isLoading)
                    const SizedBox(
                      height: 240,
                      child: Center(child: AppLoader()),
                    )
                  else if (widget.errorMessage != null)
                    _PlayerProfileError(
                      message: widget.errorMessage!,
                      onRetry: widget.onRetry,
                    )
                  else ...[
                    _PlayerIdentity(player: widget.player),
                    const SizedBox(height: AppSpacing.xl),
                    _PlayerStatistics(player: widget.player),
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(
                      title:
                          'Mutual Games (${widget.player.mutualGames.length})',
                      onViewAll: widget.onViewAllMutualGames,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _MutualGamesPreview(
                      games: widget.player.mutualGames,
                      isLoading: widget.mutualGamesLoading,
                      errorMessage: widget.mutualGamesError,
                      onTap: widget.onMutualGameTap,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _PlayerActions(
                      player: widget.player,
                      isBlocked: _isBlocked,
                      onSendInvite: _sendInvite,
                      onReport: _showReportDialog,
                      onBlock: _showBlockDialog,
                      isFavorite: _isFavorite,
                      favoriteLoading: _favoriteLoading,
                      onFavorite: _toggleFavorite,
                    ),
                  ],
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerProfileHeader extends StatelessWidget {
  const _PlayerProfileHeader({
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
            'Players Profile',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.homeGreeting,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        HeaderActionButton(
          key: const ValueKey('player-profile-header-notifications'),
          semanticsLabel: 'Notifications',
          assetPath: AppAssets.homeBellIcon,
          fallbackIcon: Icons.notifications_none,
          unreadCount: notificationCount,
          onTap: onNotificationTap,
        ),
        const SizedBox(width: AppSpacing.md),
        HeaderActionButton(
          key: const ValueKey('player-profile-header-messages'),
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

class _PlayerIdentity extends StatelessWidget {
  const _PlayerIdentity({required this.player});

  final PlayerProfileData player;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppAvatar(
          key: const ValueKey('player-profile-avatar'),
          fallbackAsset: player.avatarAsset,
          imageUrl: player.avatarUrl,
          size: 60,
        ),
        const SizedBox(height: AppSpacing.iconGap),
        Text(
          player.name,
          textAlign: TextAlign.center,
          style: AppTypography.homeMatchTitle18,
        ),
        const SizedBox(height: AppSpacing.micro),
        Text(
          player.email,
          textAlign: TextAlign.center,
          softWrap: true,
          style: AppTypography.homeMeta12,
        ),
        const SizedBox(height: AppSpacing.micro),
        Text(
          player.addressLine,
          textAlign: TextAlign.center,
          softWrap: true,
          style: AppTypography.homeMeta12,
        ),
      ],
    );
  }
}

class _PlayerStatistics extends StatelessWidget {
  const _PlayerStatistics({required this.player});

  final PlayerProfileData player;

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('Matches Played', '${player.matchesPlayed}'),
      ('Matches Hosted', '${player.matchesHosted}'),
      ('Attendance', '${player.attendancePercent}%'),
      ('Member since', player.memberSinceLabel),
    ];

    return AppSurfaceContainer(
      key: const ValueKey('player-profile-stats'),
      minHeight: 0,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          if (constraints.maxWidth < 300 || textScale > 1.4) {
            return Wrap(
              runSpacing: AppSpacing.lg,
              children: stats
                  .map(
                    (stat) => SizedBox(
                      width: constraints.maxWidth / 2,
                      child: _StatisticItem(label: stat.$1, value: stat.$2),
                    ),
                  )
                  .toList(growable: false),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: stats
                .map(
                  (stat) => Expanded(
                    child: _StatisticItem(label: stat.$1, value: stat.$2),
                  ),
                )
                .toList(growable: false),
          );
        },
      ),
    );
  }
}

class _StatisticItem extends StatelessWidget {
  const _StatisticItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          softWrap: true,
          style: AppTypography.homeMeta12,
        ),
        const SizedBox(height: AppSpacing.micro),
        Text(
          value,
          textAlign: TextAlign.center,
          style: AppTypography.homeMatchTitle16,
        ),
      ],
    );
  }
}

class _MutualGamesPreview extends StatelessWidget {
  const _MutualGamesPreview({
    required this.games,
    required this.isLoading,
    required this.errorMessage,
    this.onTap,
  });

  final List<HomeMatch> games;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<HomeMatch>? onTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(height: 140, child: Center(child: AppLoader()));
    }

    if (errorMessage != null) {
      return AppSurfaceContainer(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          errorMessage!,
          textAlign: TextAlign.center,
          style: AppTypography.body14,
        ),
      );
    }

    if (games.isEmpty) {
      return const AppSurfaceContainer(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'No mutual games yet',
          textAlign: TextAlign.center,
          style: AppTypography.body14,
        ),
      );
    }

    final visibleGames = games.take(2).toList(growable: false);
    return ListView.separated(
      key: const ValueKey('player-profile-mutual-games'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleGames.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, index) {
        final match = visibleGames[index];
        return MatchCard(
          key: ValueKey('player-profile-match-${match.id}'),
          match: match,
          showStatus: false,
          onTap: onTap == null ? null : () => onTap!(match),
        );
      },
    );
  }
}

class _PlayerActions extends StatelessWidget {
  const _PlayerActions({
    required this.player,
    required this.isBlocked,
    required this.onSendInvite,
    required this.onReport,
    required this.onBlock,
    required this.isFavorite,
    required this.favoriteLoading,
    required this.onFavorite,
  });

  final PlayerProfileData player;
  final bool isBlocked;
  final VoidCallback onSendInvite;
  final VoidCallback onReport;
  final VoidCallback onBlock;
  final bool isFavorite;
  final bool favoriteLoading;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (player.canInvite && !isBlocked)
          AppButton.primary(
            key: const ValueKey('player-profile-send-invite'),
            label: 'Send Invite',
            onPressed: onSendInvite,
          ),
        if (player.canInvite && !isBlocked && (player.canReport || (player.canBlock && !isBlocked)))
          const SizedBox(height: AppSpacing.lg),
        if (player.canReport && player.canBlock && !isBlocked)
          AppResponsiveActionPair(
            horizontalGap: AppSpacing.md,
            first: AppButton.destructiveOutlined(
              key: const ValueKey('player-profile-report'),
              label: 'Report User',
              onPressed: onReport,
              textStyle: AppTypography.matchSuccessSecondaryButton.copyWith(
                color: AppColors.destructive,
              ),
            ),
            second: AppButton.destructiveOutlined(
              key: const ValueKey('player-profile-block'),
              label: 'Block User',
              onPressed: onBlock,
              textStyle: AppTypography.matchSuccessSecondaryButton.copyWith(
                color: AppColors.destructive,
              ),
            ),
          )
        else if (player.canReport)
          AppButton.destructiveOutlined(
            key: const ValueKey('player-profile-report'),
            label: 'Report User',
            onPressed: onReport,
            textStyle: AppTypography.matchSuccessSecondaryButton.copyWith(
              color: AppColors.destructive,
            ),
          )
        else if (player.canBlock && !isBlocked)
          AppButton.destructiveOutlined(
            key: const ValueKey('player-profile-block'),
            label: 'Block User',
            onPressed: onBlock,
            textStyle: AppTypography.matchSuccessSecondaryButton.copyWith(
              color: AppColors.destructive,
            ),
          ),
        if (!isBlocked) ...[
          const SizedBox(height: AppSpacing.lg),
          AppButton.secondary(
            key: const ValueKey('player-profile-favorite'),
            label: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
            onPressed: onFavorite,
            isLoading: favoriteLoading,
            leading: Icon(
              isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              size: 20,
              color: AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }
}

class _PlayerProfileError extends StatelessWidget {
  const _PlayerProfileError({required this.message, this.onRetry});

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
