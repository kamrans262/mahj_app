import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_loader.dart';
import '../../home/domain/home_match.dart';
import '../data/match_repository.dart';
import 'match_details_screen.dart';

class ConnectedMatchDetailsScreen extends StatefulWidget {
  const ConnectedMatchDetailsScreen({
    required this.initialMatch,
    required this.repository,
    super.key,
    this.onBack,
    this.onInvitePlayers,
    this.onChat,
  });

  final HomeMatch initialMatch;
  final MatchRepository repository;
  final VoidCallback? onBack;
  final VoidCallback? onInvitePlayers;
  final MatchChatCallback? onChat;

  @override
  State<ConnectedMatchDetailsScreen> createState() =>
      _ConnectedMatchDetailsScreenState();
}

class _ConnectedMatchDetailsScreenState
    extends State<ConnectedMatchDetailsScreen> {
  late HomeMatch _match;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _match = widget.initialMatch;
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final match = await widget.repository.fetch(_match.id);
      if (!mounted) return;
      setState(() => _match = _preserveDistance(match));
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<HomeMatch> _join(HomeMatch match) async {
    final updated = _preserveDistance(
      await widget.repository.join(match.id),
    );
    if (mounted) setState(() => _match = updated);
    return updated;
  }

  Future<HomeMatch> _leave(HomeMatch match) async {
    final updated = _preserveDistance(
      await widget.repository.leave(match.id),
    );
    if (mounted) setState(() => _match = updated);
    return updated;
  }

  Future<void> _cancel(HomeMatch match) async {
    final updated = _preserveDistance(
      await widget.repository.cancel(match.id),
    );
    if (mounted) setState(() => _match = updated);
  }

  HomeMatch _preserveDistance(HomeMatch updated) {
    final distance = updated.distanceMiles ?? _match.distanceMiles;
    if (distance == null) return updated;
    return updated.copyWith(distanceMiles: distance);
  }

  String _distanceLabel(HomeMatch match) {
    final miles = match.distanceMiles;
    if (miles == null) return 'Distance unavailable';
    return '${miles.toStringAsFixed(1)} miles';
  }

  String _messageFor(Object error) {
    if (error is ApiException) return error.message;
    return 'Could not load match details. Please try again.';
  }

  String _playersSupportingText(HomeMatch match) {
    final openings = (match.maxPlayers - match.currentPlayers).clamp(
      0,
      match.maxPlayers,
    );
    if (openings == 0) {
      return '${match.currentPlayers} joined · No openings left';
    }

    return '${match.currentPlayers} joined · $openings '
        '${openings == 1 ? 'opening' : 'openings'} left';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _match.id.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: Center(child: AppLoader())),
      );
    }

    if (_error != null && _match.id.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final localizations = MaterialLocalizations.of(context);
    final localStart = _match.startsAt.toLocal();

    return MatchDetailsScreen(
      match: _match,
      onBack: widget.onBack,
      onInvitePlayers: widget.onInvitePlayers,
      onJoinMatch: _match.isOwnedByCurrentUser ? null : _join,
      onLeaveMatch: _match.canLeave ? _leave : null,
      onCancelMatch: _match.canCancel ? _cancel : null,
      onChat: widget.onChat,
      hostUserId: _match.hostUserId,
      isCurrentUserJoined: _match.isCurrentUserJoined,
      canCancelMatch: _match.canCancel,
      venueName: _match.venueName?.trim().isNotEmpty == true
          ? _match.venueName!
          : 'Match Location',
      proximityLabel: _match.location,
      dateLabel: localizations.formatMediumDate(localStart),
      timeLabel: localizations.formatTimeOfDay(
        TimeOfDay.fromDateTime(localStart),
      ),
      distanceLabel: _distanceLabel(_match),
      createdBy: _match.hostName ?? 'Host',
      playersLabel: '${_match.currentPlayers}/${_match.maxPlayers}',
      playersSupportingText: _playersSupportingText(_match),
      notes: _match.notes?.trim().isNotEmpty == true
          ? _match.notes!
          : 'No notes from host',
    );
  }
}
