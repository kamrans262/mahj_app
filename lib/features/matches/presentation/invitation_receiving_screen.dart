import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_asset_icon.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_surface_container.dart';
import '../../home/domain/home_match.dart';
import 'widgets/inviter_user_row.dart';
import 'widgets/match_info_row.dart';

typedef InvitationActionCallback = Future<void> Function(HomeMatch match);

enum InvitationAvailabilityState { invited, cannotJoin }

class InvitationReceivingScreen extends StatefulWidget {
  const InvitationReceivingScreen({
    required this.match,
    super.key,
    this.onBack,
    this.onDecline,
    this.onAccept,
    this.onOkay,
    this.initialAvailabilityState,
    this.inviterName = 'Host',
    this.inviterAvatarAsset = AppAssets.demoAvatarOne,
    this.inviterAvatarUrl,
    this.distanceLabel,
  });

  final HomeMatch match;
  final VoidCallback? onBack;
  final InvitationActionCallback? onDecline;
  final InvitationActionCallback? onAccept;
  final VoidCallback? onOkay;
  final InvitationAvailabilityState? initialAvailabilityState;
  final String inviterName;
  final String inviterAvatarAsset;
  final String? inviterAvatarUrl;
  final String? distanceLabel;

  @override
  State<InvitationReceivingScreen> createState() =>
      _InvitationReceivingScreenState();
}

class _InvitationReceivingScreenState extends State<InvitationReceivingScreen> {
  bool _isDeclining = false;
  bool _isAccepting = false;
  late InvitationAvailabilityState _availabilityState;

  @override
  void initState() {
    super.initState();
    _availabilityState = _resolveAvailabilityState();
  }

  @override
  void didUpdateWidget(covariant InvitationReceivingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialAvailabilityState != widget.initialAvailabilityState ||
        oldWidget.match.status != widget.match.status ||
        oldWidget.match.currentPlayers != widget.match.currentPlayers ||
        oldWidget.match.maxPlayers != widget.match.maxPlayers) {
      _availabilityState = _resolveAvailabilityState();
    }
  }

  InvitationAvailabilityState _resolveAvailabilityState() {
    final explicitState = widget.initialAvailabilityState;
    if (explicitState != null) return explicitState;

    final isFull =
        widget.match.status == MatchStatus.full ||
        (widget.match.maxPlayers > 0 &&
            widget.match.currentPlayers >= widget.match.maxPlayers);

    return isFull
        ? InvitationAvailabilityState.cannotJoin
        : InvitationAvailabilityState.invited;
  }

  bool get _cannotJoin =>
      _availabilityState == InvitationAvailabilityState.cannotJoin;

  TextStyle get _valueStyle {
    return AppTypography.field.copyWith(
      color: AppColors.heading,
      fontWeight: FontWeight.w500,
    );
  }

  String get _statusLabel {
    switch (widget.match.status) {
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
    switch (widget.match.status) {
      case MatchStatus.open:
      case MatchStatus.completed:
        return AppColors.matchSuccess;
      case MatchStatus.cancelled:
        return AppColors.destructive;
      case MatchStatus.confirmed:
      case MatchStatus.full:
        return AppColors.textSecondary;
    }
  }

  String get _distanceLabel {
    final explicit = widget.distanceLabel?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }

    final miles = widget.match.distanceMiles;
    if (miles != null) {
      return '${miles.toStringAsFixed(1)} miles';
    }

    final location = widget.match.location.trim();
    return location.isEmpty ? 'Distance unavailable' : location;
  }

  String get _playersSupportingText {
    final openings = (widget.match.maxPlayers - widget.match.currentPlayers)
        .clamp(0, widget.match.maxPlayers);
    final openingLabel = openings == 1 ? 'opening' : 'openings';
    return '${widget.match.currentPlayers} joined · $openings $openingLabel left';
  }

  Future<void> _decline() async {
    if (_isDeclining || _isAccepting) return;

    final callback = widget.onDecline;
    if (callback == null) {
      _showMessage('Declining invitations is not connected yet.');
      return;
    }

    setState(() => _isDeclining = true);
    try {
      await callback(widget.match);
    } catch (_) {
      if (mounted) {
        _showMessage('Could not decline the invitation. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isDeclining = false);
    }
  }

  Future<void> _accept() async {
    if (_isAccepting || _isDeclining) return;

    final callback = widget.onAccept;
    if (callback == null) {
      _showMessage('Accepting invitations is not connected yet.');
      return;
    }

    setState(() => _isAccepting = true);
    try {
      await callback(widget.match);
    } catch (_) {
      if (mounted) {
        _showMessage('Could not accept the invitation. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  void _okay() {
    final callback = widget.onOkay;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).maybePop();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('invitation-receiving-screen'),
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
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
              child: ListView(
                key: const ValueKey('invitation-receiving-scroll'),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal,
                  AppSpacing.lg,
                  AppSpacing.pageHorizontal,
                  AppSpacing.lg,
                ),
                children: [
                  _InvitationHero(cannotJoin: _cannotJoin),
                  const SizedBox(height: AppSpacing.lg),
                  InviterUserRow(
                    avatarAsset: widget.inviterAvatarAsset,
                    avatarUrl: widget.inviterAvatarUrl,
                    inviterName: widget.inviterName,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.divider,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  MatchInfoRow(
                    iconAsset: AppAssets.matchDetailsCalendarIcon,
                    label: 'Date',
                    value: Text(
                      _formatDate(widget.match.startsAt),
                      style: _valueStyle,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  MatchInfoRow(
                    iconAsset: AppAssets.matchDetailsTimeIcon,
                    label: 'Time',
                    value: Text(
                      _formatTime(widget.match.startsAt),
                      style: _valueStyle,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  MatchInfoRow(
                    iconAsset: AppAssets.matchDetailsDistanceIcon,
                    label: 'Distance',
                    value: Text(_distanceLabel, style: _valueStyle),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.divider,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  MatchInfoRow(
                    iconAsset: AppAssets.matchDetailsPlayersIcon,
                    label: 'Players',
                    value: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.match.currentPlayers}/${widget.match.maxPlayers}',
                          style: _valueStyle,
                        ),
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
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal,
                  AppSpacing.sm,
                  AppSpacing.pageHorizontal,
                  AppSpacing.lg,
                ),
                child: _buildBottomActions(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    if (_cannotJoin) {
      return AppButton.destructive(
        key: const ValueKey('invitation-okay'),
        label: 'Okay',
        textStyle: AppTypography.primaryButton,
        onPressed: _okay,
      );
    }

    return Row(
      children: [
        Expanded(
          child: AppButton.secondary(
            key: const ValueKey('invitation-decline'),
            label: 'Decline',
            isLoading: _isDeclining,
            isEnabled: !_isAccepting,
            textStyle: AppTypography.matchSuccessSecondaryButton,
            onPressed: _decline,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: AppButton.primary(
            key: const ValueKey('invitation-accept'),
            label: 'Accept',
            isLoading: _isAccepting,
            isEnabled: !_isDeclining,
            textStyle: AppTypography.matchSuccessSecondaryButton.copyWith(
              color: Colors.white,
            ),
            onPressed: _accept,
          ),
        ),
      ],
    );
  }
}

class _InvitationHero extends StatelessWidget {
  const _InvitationHero({required this.cannotJoin});

  final bool cannotJoin;

  @override
  Widget build(BuildContext context) {
    final imageAsset = cannotJoin
        ? AppAssets.invitationCannotJoinImage
        : AppAssets.invitationReceivedImage;
    final title = cannotJoin ? 'You Cannot Join' : 'You are Invited';
    final subtitle = cannotJoin
        ? 'This match is already full'
        : 'Please join the game';

    return SizedBox(
      key: const ValueKey('invitation-hero'),
      width: double.infinity,
      child: AppSurfaceContainer(
        minHeight: 0,
        backgroundColor: AppColors.invitationHeroSurface,
        borderColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppAssetIcon(assetPath: imageAsset, size: 112),
            const SizedBox(height: AppSpacing.iconGap),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.homeMatchTitle18,
            ),
            const SizedBox(height: AppSpacing.micro),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.homeMeta14,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(value.year, value.month, value.day);
  final dayDifference = target.difference(today).inDays;
  final dateLabel = '${months[value.month - 1]} ${value.day}';

  if (dayDifference == 1) return 'Tomorrow, $dateLabel';
  if (dayDifference == 0) return 'Today, $dateLabel';
  return dateLabel;
}

String _formatTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}
