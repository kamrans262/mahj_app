import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_loader.dart';
import '../../home/domain/home_match.dart';
import '../data/match_repository.dart';
import '../domain/match_completion_data.dart';
import '../domain/match_score_player.dart';
import 'match_completed_screen.dart';

class ConnectedMatchCompletedScreen extends StatefulWidget {
  const ConnectedMatchCompletedScreen({
    required this.initialMatch,
    required this.repository,
    required this.currentUserId,
    super.key,
    this.onBack,
    this.onPlayerTap,
  });

  final HomeMatch initialMatch;
  final MatchRepository repository;
  final String currentUserId;
  final VoidCallback? onBack;
  final ValueChanged<MatchScorePlayer>? onPlayerTap;

  @override
  State<ConnectedMatchCompletedScreen> createState() =>
      _ConnectedMatchCompletedScreenState();
}

class _ConnectedMatchCompletedScreenState
    extends State<ConnectedMatchCompletedScreen> {
  MatchCompletionData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await widget.repository.fetchCompletion(
        widget.initialMatch.id,
        currentUserId: widget.currentUserId,
      );
      if (!mounted) return;
      setState(() => _data = data);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitScores(
    String matchId,
    Map<String, int> scores,
  ) async {
    final data = await widget.repository.submitScores(
      matchId,
      scores,
      currentUserId: widget.currentUserId,
    );
    if (!mounted) return;
    setState(() => _data = data);
  }

  String _messageFor(Object error) {
    if (error is ApiException) return error.message;
    return 'Could not load completed match. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;

    if (_loading && data == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: Center(child: AppLoader())),
      );
    }

    if (_error != null && data == null) {
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
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (data == null) {
      return const SizedBox.shrink();
    }

    return MatchCompletedScreen(
      match: data.match,
      players: data.players,
      inviterName: data.match.hostName ?? 'Host',
      inviterAvatarUrl: data.match.hostAvatarUrl,
      scoresAlreadySubmitted: data.scoresSubmitted,
      canSubmitScores: data.canSubmitScores,
      onBack: widget.onBack,
      onPlayerTap: widget.onPlayerTap,
      onSubmitScores: data.canSubmitScores ? _submitScores : null,
    );
  }
}
