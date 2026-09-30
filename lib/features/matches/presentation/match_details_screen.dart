import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_asset_icon.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../core/widgets/app_responsive_action_pair.dart';
import '../../../core/widgets/app_status_dialog.dart';
import '../../home/domain/home_match.dart';
import '../domain/match_report.dart';
import 'widgets/match_location_map.dart';
import 'widgets/match_info_row.dart';
import 'widgets/report_match_dialog.dart';

typedef MatchJoinCallback = Future<HomeMatch> Function(HomeMatch match);
typedef MatchLeaveCallback = Future<HomeMatch> Function(HomeMatch match);
typedef MatchCancelCallback = Future<void> Function(HomeMatch match);
typedef MatchChatCallback = void Function(String matchId);
typedef MatchReportCallback = Future<void> Function(ReportMatchRequest request);

class MatchDetailsScreen extends StatefulWidget {
  const MatchDetailsScreen({
    required this.match,
    super.key,
    this.onBack,
    this.onInvitePlayers,
    this.onReport,
    this.onJoinMatch,
    this.onLeaveMatch,
    this.onChat,
    this.onCancelMatch,
    this.onSubmitReport,
    this.hostUserId,
    this.isCurrentUserJoined = false,
    this.canCancelMatch = false,
    this.venueName = 'Central Park View',
    this.proximityLabel = '0.8 miles away',
    this.dateLabel = 'Tomorrow, May 25',
    this.timeLabel = '6:00 PM',
    this.distanceLabel = '2 miles',
    this.createdBy = 'Alex Turner',
    this.playersLabel = '2/4',
    this.playersSupportingText = '3 joined · 1 opening left',
    this.notes = 'Let’s have a great match',
  });

  final HomeMatch match;
  final VoidCallback? onBack;
  final VoidCallback? onInvitePlayers;
  final VoidCallback? onReport;
  final MatchJoinCallback? onJoinMatch;
  final MatchLeaveCallback? onLeaveMatch;
  final MatchChatCallback? onChat;
  final MatchCancelCallback? onCancelMatch;
  final MatchReportCallback? onSubmitReport;
  final String? hostUserId;

  /// Backend/controller-provided participation state for the current user.
  final bool isCurrentUserJoined;

  /// Backend/domain permission flag. Joined players are not assumed to be able
  /// to cancel the entire match.
  final bool canCancelMatch;

  final String venueName;
  final String proximityLabel;
  final String dateLabel;
  final String timeLabel;
  final String distanceLabel;
  final String createdBy;
  final String playersLabel;
  final String playersSupportingText;
  final String notes;

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  late HomeMatch _match;
  late String _playersLabel;
  late String _playersSupportingText;
  late bool _isCurrentUserJoined;

  bool _isJoinDialogOpen = false;
  bool _joinRequestInFlight = false;
  bool _isLeaveDialogOpen = false;
  bool _leaveRequestInFlight = false;
  bool _isCancelDialogOpen = false;
  bool _cancelRequestInFlight = false;
  bool _isStatusDialogOpen = false;
  bool _isReportDialogOpen = false;
  bool _reportRequestInFlight = false;

  @override
  void initState() {
    super.initState();
    _match = widget.match;
    _playersLabel = widget.playersLabel;
    _playersSupportingText = widget.playersSupportingText;
    _isCurrentUserJoined = widget.isCurrentUserJoined;
  }

  @override
  void didUpdateWidget(covariant MatchDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.match.id != widget.match.id) {
      _match = widget.match;
      _playersLabel = widget.playersLabel;
      _playersSupportingText = widget.playersSupportingText;
      _isCurrentUserJoined = widget.isCurrentUserJoined;
      return;
    }

    if (oldWidget.match != widget.match &&
        !_joinRequestInFlight &&
        !_leaveRequestInFlight) {
      _match = widget.match;
    }

    if (oldWidget.playersLabel != widget.playersLabel &&
        !_joinRequestInFlight &&
        !_leaveRequestInFlight) {
      _playersLabel = widget.playersLabel;
    }

    if (oldWidget.playersSupportingText != widget.playersSupportingText &&
        !_joinRequestInFlight &&
        !_leaveRequestInFlight) {
      _playersSupportingText = widget.playersSupportingText;
    }

    if (oldWidget.isCurrentUserJoined != widget.isCurrentUserJoined &&
        !_joinRequestInFlight &&
        !_leaveRequestInFlight) {
      _isCurrentUserJoined = widget.isCurrentUserJoined;
    }
  }

  String get _statusLabel {
    switch (_match.status) {
      case MatchStatus.open:
        return 'Open';
      case MatchStatus.confirmed:
        return 'Confirmed';
      case MatchStatus.cancelled:
        return 'Cancelled';
      case MatchStatus.full:
        return 'Full';
      case MatchStatus.completed:
        return 'Completed';
    }
  }

  Color get _statusColor {
    return switch (_match.status) {
      MatchStatus.open || MatchStatus.completed => AppColors.matchSuccess,
      MatchStatus.cancelled => AppColors.destructive,
      MatchStatus.confirmed || MatchStatus.full => AppColors.textSecondary,
    };
  }

  bool get _canJoin {
    return !_isCurrentUserJoined &&
        _match.isJoinable &&
        _match.status == MatchStatus.open &&
        !_match.isFull;
  }

  TextStyle get _valueStyle {
    return AppTypography.field.copyWith(
      color: AppColors.heading,
      fontWeight: FontWeight.w500,
    );
  }

  Future<void> _handleJoinTap() async {
    if (_isCurrentUserJoined) return;

    if (_match.status == MatchStatus.cancelled) {
      await _showMatchCancelledStatus();
      return;
    }

    if (_match.isFull || _match.status == MatchStatus.full) {
      await _showMatchFullStatus();
      return;
    }

    if (!_match.isJoinable || _match.status != MatchStatus.open) {
      _showMessage('This match is not available to join.');
      return;
    }

    await _showJoinConfirmation();
  }

  Future<void> _showJoinConfirmation() async {
    if (!_canJoin || _isJoinDialogOpen) return;

    _isJoinDialogOpen = true;

    try {
      final joined = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Join match confirmation',
        barrierColor: AppColors.confirmationBackdrop,
        transitionDuration: const Duration(milliseconds: 160),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          var isLoading = false;

          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              final navigator = Navigator.of(dialogContext);

              Future<void> confirmJoin() async {
                if (isLoading) return;

                setDialogState(() => isLoading = true);
                final didJoin = await _submitJoin();

                if (!navigator.mounted) return;

                if (didJoin) {
                  navigator.pop(true);
                  return;
                }

                setDialogState(() => isLoading = false);
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
                        title: 'Join Confirmation',
                        message: 'Are you sure you want to join this match?',
                        cancelLabel: 'Cancel',
                        confirmLabel: 'Join',
                        isLoading: isLoading,
                        onCancel: isLoading ? null : () => navigator.pop(false),
                        onConfirm: isLoading ? null : confirmJoin,
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

      if (joined == true && mounted) {
        await _showJoinedSuccessfullyStatus();
      }
    } finally {
      _isJoinDialogOpen = false;
    }
  }

  Future<bool> _submitJoin() async {
    if (_joinRequestInFlight) return false;

    final callback = widget.onJoinMatch;
    if (callback == null) {
      _showMessage('Joining matches is not connected yet.');
      return false;
    }

    _joinRequestInFlight = true;

    try {
      final joinedMatch = await callback(_match);
      if (!mounted) return false;

      if (joinedMatch.id != _match.id) {
        throw StateError('Join response does not match the selected match.');
      }

      setState(() {
        _applyBackendMatch(joinedMatch);
        _isCurrentUserJoined = true;
      });

      return true;
    } catch (_) {
      if (mounted) {
        _showMessage('Could not join the match. Please try again.');
      }
      return false;
    } finally {
      _joinRequestInFlight = false;
    }
  }

  Future<void> _showLeaveConfirmation() async {
    if (!_isCurrentUserJoined || _isLeaveDialogOpen) return;

    _isLeaveDialogOpen = true;

    try {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Leave match confirmation',
        barrierColor: AppColors.confirmationBackdrop,
        transitionDuration: const Duration(milliseconds: 160),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          var isLoading = false;

          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              final navigator = Navigator.of(dialogContext);

              Future<void> confirmLeave() async {
                if (isLoading) return;

                setDialogState(() => isLoading = true);
                final left = await _submitLeave();

                if (!navigator.mounted) return;

                if (left) {
                  navigator.pop();
                  return;
                }

                setDialogState(() => isLoading = false);
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
                        title: 'Leave Confirmation',
                        message: 'Are you sure you want to leave this match?',
                        cancelLabel: 'Cancel',
                        confirmLabel: 'Leave',
                        confirmVariant: AppConfirmationVariant.destructive,
                        isLoading: isLoading,
                        onCancel: isLoading ? null : () => navigator.pop(),
                        onConfirm: isLoading ? null : confirmLeave,
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
    } finally {
      _isLeaveDialogOpen = false;
    }
  }

  Future<bool> _submitLeave() async {
    if (_leaveRequestInFlight) return false;

    final callback = widget.onLeaveMatch;
    if (callback == null) {
      _showMessage('Leaving matches is not connected yet.');
      return false;
    }

    _leaveRequestInFlight = true;

    try {
      final leftMatch = await callback(_match);
      if (!mounted) return false;

      if (leftMatch.id != _match.id) {
        throw StateError('Leave response does not match the selected match.');
      }

      setState(() {
        _applyBackendMatch(leftMatch);
        _isCurrentUserJoined = false;
      });

      return true;
    } catch (_) {
      if (mounted) {
        _showMessage('Could not leave the match. Please try again.');
      }
      return false;
    } finally {
      _leaveRequestInFlight = false;
    }
  }

  void _applyBackendMatch(HomeMatch match) {
    _match = match;
    _playersLabel = '${match.currentPlayers}/${match.maxPlayers}';
    _playersSupportingText = _playersSupportingTextFor(match);
  }

  String _playersSupportingTextFor(HomeMatch match) {
    final openings = (match.maxPlayers - match.currentPlayers).clamp(
      0,
      match.maxPlayers,
    );

    if (openings == 0) {
      return '${match.currentPlayers} joined · No openings left';
    }

    final openingLabel = openings == 1 ? 'opening' : 'openings';
    return '${match.currentPlayers} joined · $openings $openingLabel left';
  }

  void _openChat() {
    final callback = widget.onChat;
    if (callback == null) {
      _showMessage('Match chat is not connected yet.');
      return;
    }

    callback(_match.id);
  }

  Future<void> _showCancelConfirmation() async {
    if (!widget.canCancelMatch || _isCancelDialogOpen) return;

    _isCancelDialogOpen = true;

    try {
      final cancelled = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Cancel match confirmation',
        barrierColor: AppColors.confirmationBackdrop,
        transitionDuration: const Duration(milliseconds: 160),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          var isLoading = false;

          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              final navigator = Navigator.of(dialogContext);

              Future<void> confirmCancel() async {
                if (isLoading) return;

                setDialogState(() => isLoading = true);
                final didCancel = await _submitCancelMatch();

                if (!navigator.mounted) return;

                if (didCancel) {
                  navigator.pop(true);
                  return;
                }

                setDialogState(() => isLoading = false);
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
                        title: 'Cancel Confirmation',
                        message: 'Are you sure you want to cancel this match?',
                        cancelLabel: 'Cancel',
                        confirmLabel: 'Confirm',
                        confirmVariant: AppConfirmationVariant.destructive,
                        isLoading: isLoading,
                        onCancel: isLoading ? null : () => navigator.pop(false),
                        onConfirm: isLoading ? null : confirmCancel,
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

      if (cancelled == true && mounted) {
        await _showMatchCancelledStatus();
      }
    } finally {
      _isCancelDialogOpen = false;
    }
  }

  Future<bool> _submitCancelMatch() async {
    if (_cancelRequestInFlight) return false;

    final callback = widget.onCancelMatch;
    if (callback == null) {
      _showMessage('Match cancellation is not connected yet.');
      return false;
    }

    _cancelRequestInFlight = true;

    try {
      await callback(_match);
      return true;
    } catch (_) {
      if (mounted) {
        _showMessage('Could not cancel the match. Please try again.');
      }
      return false;
    } finally {
      _cancelRequestInFlight = false;
    }
  }

  Future<void> _showJoinedSuccessfullyStatus() {
    return _showStatusDialog(
      barrierLabel: 'Joined successfully',
      title: 'Joined Successfully',
      message: 'You have joined the match',
      icon: const AppStatusCircleIcon(
        backgroundColor: AppColors.matchSuccess,
        icon: Icons.check_rounded,
      ),
    );
  }

  Future<void> _showMatchCancelledStatus() {
    return _showStatusDialog(
      barrierLabel: 'Match cancelled',
      title: 'Match Cancelled',
      message: 'This match has been cancelled by\nhost',
      icon: const AppStatusCircleIcon(
        backgroundColor: AppColors.destructive,
        icon: Icons.close_rounded,
      ),
    );
  }

  Future<void> _showMatchFullStatus() {
    return _showStatusDialog(
      barrierLabel: 'Match full',
      title: 'Match Full',
      message: 'Sorry this match is already full',
      icon: AppAssetIcon(
        assetPath: AppAssets.matchDetailsPlayersIcon,
        size: 34,
        color: AppColors.textSecondary,
      ),
    );
  }

  Future<void> _showStatusDialog({
    required String barrierLabel,
    required String title,
    required String message,
    required Widget icon,
  }) async {
    if (_isStatusDialogOpen || !mounted) return;

    _isStatusDialogOpen = true;

    try {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: barrierLabel,
        barrierColor: AppColors.confirmationBackdrop,
        transitionDuration: const Duration(milliseconds: 160),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageHorizontal,
                  vertical: AppSpacing.lg,
                ),
                child: AppStatusDialog(
                  title: title,
                  message: message,
                  icon: icon,
                ),
              ),
            ),
          );
        },
        transitionBuilder: _modalTransition,
      );
    } finally {
      _isStatusDialogOpen = false;
    }
  }

  Future<void> _showReportDialog() async {
    if (_isReportDialogOpen) return;

    _isReportDialogOpen = true;

    try {
      final submitted = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Report match host',
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
                    hostName: widget.createdBy,
                    reasons: demoReportReasons,
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

      if (submitted == true && mounted) {
        widget.onReport?.call();
        _showMessage('Report submitted');
      }
    } finally {
      _isReportDialogOpen = false;
    }
  }

  Future<bool> _submitReport(ReportReason reason, String notes) async {
    if (_reportRequestInFlight) return false;

    final callback = widget.onSubmitReport;
    final reportedUserId = widget.hostUserId?.trim();

    if (callback == null || reportedUserId == null || reportedUserId.isEmpty) {
      _showMessage('Reporting is not connected yet.');
      return false;
    }

    _reportRequestInFlight = true;

    try {
      await callback(
        ReportMatchRequest(
          matchId: _match.id,
          reportedUserId: reportedUserId,
          reasonId: reason.id,
          notes: notes,
        ),
      );

      return true;
    } catch (_) {
      if (mounted) {
        _showMessage('Could not submit the report. Please try again.');
      }
      return false;
    } finally {
      _reportRequestInFlight = false;
    }
  }

  Widget _modalTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
        child: child,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleInvitePlayers() {
    final callback = widget.onInvitePlayers;
    if (callback == null) {
      _showMessage('Invite Players navigation is not connected.');
      return;
    }

    callback();
  }

  Widget _buildActions() {
    if (widget.canCancelMatch) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppResponsiveActionPair(
            first: AppButton.secondary(
              key: const ValueKey('match-details-invite-players'),
              label: 'Invite Players',
              textStyle: AppTypography.matchSuccessSecondaryButton,
              onPressed: _handleInvitePlayers,
            ),
            second: AppButton.secondary(
              label: 'Chat',
              textStyle: AppTypography.matchSuccessSecondaryButton,
              onPressed: _openChat,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton.destructiveOutlined(
            label: 'Cancel Match',
            textStyle: AppTypography.matchSuccessSecondaryButton.copyWith(
              color: AppColors.destructive,
            ),
            onPressed: _cancelRequestInFlight ? null : _showCancelConfirmation,
          ),
        ],
      );
    }

    if (_isCurrentUserJoined) {
      final chatButton = AppButton.secondary(
        label: 'Chat',
        textStyle: AppTypography.matchSuccessSecondaryButton,
        onPressed: _openChat,
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.onInvitePlayers != null)
            AppResponsiveActionPair(
              first: AppButton.secondary(
                key: const ValueKey('match-details-invite-players'),
                label: 'Invite Players',
                textStyle: AppTypography.matchSuccessSecondaryButton,
                onPressed: _handleInvitePlayers,
              ),
              second: chatButton,
            )
          else
            chatButton,
          const SizedBox(height: AppSpacing.lg),
          AppButton.primary(
            label: 'Leave Match',
            onPressed: _leaveRequestInFlight ? null : _showLeaveConfirmation,
          ),
        ],
      );
    }

    final reportButton = AppButton.secondary(
      label: 'Report',
      textStyle: AppTypography.matchSuccessSecondaryButton,
      onPressed: _showReportDialog,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.onInvitePlayers != null)
          AppResponsiveActionPair(
            first: AppButton.secondary(
              key: const ValueKey('match-details-invite-players'),
              label: 'Invite Players',
              textStyle: AppTypography.matchSuccessSecondaryButton,
              onPressed: _handleInvitePlayers,
            ),
            second: reportButton,
          )
        else
          reportButton,
        const SizedBox(height: AppSpacing.lg),
        AppButton.primary(
          label: 'Join Match',
          onPressed: _joinRequestInFlight ? null : _handleJoinTap,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                title: 'Match Details',
                onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('match-details-scroll-view'),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageHorizontal,
                  vertical: 30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MatchLocationMap(match: _match),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      widget.venueName,
                      style: AppTypography.homeSectionHeading,
                    ),
                    const SizedBox(height: AppSpacing.micro),
                    Text(
                      widget.proximityLabel,
                      style: AppTypography.homeMeta14,
                    ),
                    const SizedBox(height: 30),
                    MatchInfoRow(
                      iconAsset: AppAssets.matchDetailsCalendarIcon,
                      label: 'Date',
                      value: Text(widget.dateLabel, style: _valueStyle),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    MatchInfoRow(
                      iconAsset: AppAssets.matchDetailsTimeIcon,
                      label: 'Time',
                      value: Text(widget.timeLabel, style: _valueStyle),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    MatchInfoRow(
                      iconAsset: AppAssets.matchDetailsDistanceIcon,
                      label: 'Distance',
                      value: Text(widget.distanceLabel, style: _valueStyle),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    MatchInfoRow(
                      iconAsset: AppAssets.matchDetailsCreatedByIcon,
                      label: 'Created By',
                      value: Text(widget.createdBy, style: _valueStyle),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    MatchInfoRow(
                      iconAsset: AppAssets.matchDetailsPlayersIcon,
                      label: 'Players',
                      value: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_playersLabel, style: _valueStyle),
                          const SizedBox(height: AppSpacing.micro),
                          Text(
                            _playersSupportingText,
                            style: AppTypography.homeMeta12.copyWith(
                              color: AppColors.heading,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    MatchInfoRow(
                      iconAsset: AppAssets.matchDetailsStatusIcon,
                      label: 'Match Status',
                      value: Text(
                        _statusLabel,
                        style: _valueStyle.copyWith(color: _statusColor),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text('Notes from Host', style: AppTypography.title18),
                    const SizedBox(height: AppSpacing.micro),
                    Text(widget.notes, style: AppTypography.homeMeta14),
                    const SizedBox(height: AppSpacing.lg),
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
