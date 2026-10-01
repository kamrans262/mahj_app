import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../profile/data/player_profile_preview_data.dart';
import '../../profile/domain/player_profile_data.dart';
import '../data/privacy_safety_repository.dart';
import '../domain/privacy_safety_data.dart';
import 'privacy_safety_screen.dart';

class ConnectedPrivacySafetyScreen extends StatefulWidget {
  const ConnectedPrivacySafetyScreen({
    required this.repository,
    super.key,
    this.onBack,
    this.onPlayerTap,
  });

  final PrivacySafetyRepository repository;
  final VoidCallback? onBack;
  final Future<void> Function(PlayerProfileData player)? onPlayerTap;

  @override
  State<ConnectedPrivacySafetyScreen> createState() =>
      _ConnectedPrivacySafetyScreenState();
}

class _ConnectedPrivacySafetyScreenState
    extends State<ConnectedPrivacySafetyScreen> {
  PrivacySafetyData? _data;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final data = await widget.repository.load();
      if (!mounted) return;
      setState(() => _data = data);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _messageFor(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _unblock(String playerId) async {
    try {
      await widget.repository.unblockPlayer(playerId);
      return true;
    } catch (error) {
      if (mounted) _showMessage(_messageFor(error));
      return false;
    }
  }

  Future<void> _openPlayer(PrivacySafetyUser player) async {
    final callback = widget.onPlayerTap;
    if (callback == null) return;

    final isBlocked =
        _data?.blockedUsers.any((item) => item.id == player.id) ?? false;

    await callback(
      PlayerProfilePreviewData.forIdentity(
        id: player.id,
        displayName: player.displayName,
        avatarAsset: AppAssets.bottomProfileIcon,
        avatarUrl: player.avatarUrl,
        canInvite: !isBlocked,
        canBlock: !isBlocked,
      ),
    );

    if (mounted) await _load();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _messageFor(Object error) {
    if (error is ApiException) return error.message;
    return 'Could not load privacy and safety settings. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;

    return PrivacySafetyScreen(
      blockedUsers: data?.blockedUsers ?? const <PrivacySafetyUser>[],
      rules: privacySafetyRules,
      reportHistory:
          data?.reportHistory ?? const <PrivacyReportHistoryEntry>[],
      onBack: widget.onBack,
      onUnblock: _unblock,
      onPlayerTap: _openPlayer,
      onRetry: _load,
      isLoading: _loading && data == null,
      errorMessage: data == null ? _errorMessage : null,
    );
  }
}
