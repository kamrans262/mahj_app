import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_asset_icon.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_success_message.dart';
import '../../../core/widgets/app_surface_container.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../home/domain/home_match.dart';
import '../domain/match_score_player.dart';
import 'widgets/inviter_user_row.dart';
import 'widgets/match_info_row.dart';

typedef SubmitMatchScoresCallback = Future<void> Function(
  String matchId,
  Map<String, int> scores,
);
typedef MatchCompletedPlayerTapCallback = void Function(MatchScorePlayer player);

class MatchCompletedScreen extends StatefulWidget {
  const MatchCompletedScreen({
    required this.match,
    required this.players,
    super.key,
    this.onBack,
    this.onSubmitScores,
    this.onPlayerTap,
    this.inviterName = 'Host',
    this.inviterAvatarAsset = AppAssets.demoAvatarOne,
    this.inviterAvatarUrl,
    this.scoresAlreadySubmitted = false,
    this.canSubmitScores = true,
  });

  final HomeMatch match;
  final List<MatchScorePlayer> players;
  final VoidCallback? onBack;
  final SubmitMatchScoresCallback? onSubmitScores;
  final MatchCompletedPlayerTapCallback? onPlayerTap;
  final String inviterName;
  final String inviterAvatarAsset;
  final String? inviterAvatarUrl;
  final bool scoresAlreadySubmitted;
  final bool canSubmitScores;

  @override
  State<MatchCompletedScreen> createState() => _MatchCompletedScreenState();
}

class _MatchCompletedScreenState extends State<MatchCompletedScreen> {
  final _scoreControllers = <String, TextEditingController>{};
  bool _isSubmitting = false;
  late bool _submitted;

  TextStyle get _valueStyle => AppTypography.field.copyWith(
    color: AppColors.heading,
    fontWeight: FontWeight.w500,
  );

  @override
  void initState() {
    super.initState();
    _submitted = widget.scoresAlreadySubmitted;
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant MatchCompletedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.players != widget.players) {
      _syncControllers();
    }
    if (oldWidget.scoresAlreadySubmitted != widget.scoresAlreadySubmitted) {
      _submitted = widget.scoresAlreadySubmitted;
    }
  }

  void _syncControllers() {
    final validIds = widget.players.map((player) => player.id).toSet();
    final staleIds = _scoreControllers.keys
        .where((id) => !validIds.contains(id))
        .toList(growable: false);

    for (final id in staleIds) {
      _scoreControllers.remove(id)?.dispose();
    }

    for (final player in widget.players) {
      _scoreControllers.putIfAbsent(
        player.id,
        () =>
            TextEditingController(text: player.initialScore?.toString() ?? ''),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _scoreControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String get _playerSupportingText {
    final openings = (widget.match.maxPlayers - widget.match.currentPlayers)
        .clamp(0, widget.match.maxPlayers);
    final openingLabel = openings == 1 ? 'opening' : 'openings';
    return '${widget.match.currentPlayers} joined · $openings $openingLabel left';
  }

  Future<void> _submitScores() async {
    if (_isSubmitting || _submitted) return;

    final scores = <String, int>{};
    for (final player in widget.players) {
      final raw = _scoreControllers[player.id]?.text.trim() ?? '';
      final parsed = int.tryParse(raw);
      if (parsed == null) {
        _showMessage('Enter a numeric score for ${player.displayName}.');
        return;
      }
      scores[player.id] = parsed;
    }

    final callback = widget.onSubmitScores;
    if (callback == null) {
      _showMessage('Score submission is not connected yet.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await callback(widget.match.id, Map.unmodifiable(scores));
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() => _submitted = true);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not submit scores. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
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
                title: '',
                onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.zero,
                children: [
                  const _MatchCompletedHero(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageHorizontal,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.xl),
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
                            _formatDate(widget.match.startsAt.toLocal()),
                            style: _valueStyle,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        MatchInfoRow(
                          iconAsset: AppAssets.matchDetailsTimeIcon,
                          label: 'Time',
                          value: Text(
                            _formatTime(widget.match.startsAt.toLocal()),
                            style: _valueStyle,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        MatchInfoRow(
                          iconAsset: AppAssets.matchDetailsDistanceIcon,
                          label: 'Location',
                          value: Text(
                            widget.match.location,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _valueStyle,
                          ),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.match.currentPlayers}/${widget.match.maxPlayers}',
                                style: _valueStyle,
                              ),
                              const SizedBox(height: AppSpacing.micro),
                              Text(
                                _playerSupportingText,
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
                            'Completed',
                            style: _valueStyle.copyWith(
                              color: AppColors.matchSuccess,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.divider,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Scores',
                          style: AppTypography.homeSectionHeading,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (widget.players.isEmpty)
                          const AppSurfaceContainer(
                            minHeight: 80,
                            child: Center(
                              child: Text(
                                'No eligible players found',
                                style: AppTypography.body14,
                              ),
                            ),
                          )
                        else
                          ...List.generate(
                            widget.players.length * 2 - 1,
                            (index) {
                              if (index.isOdd) {
                                return const SizedBox(
                                  height: AppSpacing.lg,
                                );
                              }
                              final player = widget.players[index ~/ 2];
                              return _ScoreRow(
                                player: player,
                                controller: _scoreControllers[player.id]!,
                                enabled: !_submitted && !_isSubmitting,
                                onPlayerTap:
                                    player.isCurrentUser ||
                                        widget.onPlayerTap == null
                                    ? null
                                    : () => widget.onPlayerTap!(player),
                              );
                            },
                          ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.sm,
                AppSpacing.pageHorizontal,
                AppSpacing.lg,
              ),
              child: _submitted
                  ? const AppSuccessMessage(
                      message: 'Scores Submitted Successfully!',
                    )
                  : widget.canSubmitScores
                  ? AppButton.primary(
                      label: 'Submit Scores',
                      isLoading: _isSubmitting,
                      isEnabled: widget.players.isNotEmpty && !_isSubmitting,
                      onPressed: _submitScores,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchCompletedHero extends StatelessWidget {
  const _MatchCompletedHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: AppColors.invitationHeroSurface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppAssetIcon(
            assetPath: AppAssets.matchCompletedSuccessIcon,
            size: 48,
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              'Match Completed',
              maxLines: 2,
              textAlign: TextAlign.center,
              style: AppTypography.homeMatchTitle18,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.player,
    required this.controller,
    required this.enabled,
    this.onPlayerTap,
  });

  final MatchScorePlayer player;
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback? onPlayerTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: onPlayerTap != null,
            label: onPlayerTap == null
                ? null
                : 'Open ${player.displayName} safety options',
            child: InkWell(
              onTap: onPlayerTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    AppAvatar(
                      fallbackAsset: player.avatarAsset,
                      imageUrl: player.avatarUrl,
                      size: 30,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        player.isCurrentUser ? 'You' : player.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.homeMatchTitle16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 68, maxWidth: 84),
          child: AppTextField(
            key: ValueKey('match-score-${player.id}'),
            controller: controller,
            hintText: '',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            enabled: enabled,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 11,
            ),
          ),
        ),
      ],
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
