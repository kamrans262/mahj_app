import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../home/domain/home_match.dart';
import '../data/chat_repository.dart';
import '../domain/chat_models.dart';
import 'match_chat_screen.dart';

class ConnectedMatchChatScreen extends StatefulWidget {
  const ConnectedMatchChatScreen({
    required this.match,
    required this.repository,
    required this.currentUserId,
    super.key,
    this.currentUserAvatarUrl,
    this.onBack,
    this.onPlayerTap,
  });

  final HomeMatch match;
  final ChatRepository repository;
  final String currentUserId;
  final String? currentUserAvatarUrl;
  final VoidCallback? onBack;
  final ChatPlayerTapCallback? onPlayerTap;

  @override
  State<ConnectedMatchChatScreen> createState() =>
      _ConnectedMatchChatScreenState();
}

class _ConnectedMatchChatScreenState extends State<ConnectedMatchChatScreen> {
  static const Duration _pollInterval = Duration(seconds: 4);

  List<ChatParticipant> _participants = const [];
  List<ChatMessage> _messages = const [];
  bool _initialLoading = true;
  bool _loadingOlder = false;
  bool _hasMoreOlder = false;
  bool _canSend = true;
  bool _pollInFlight = false;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    _pollTimer?.cancel();
    if (mounted) {
      setState(() {
        _initialLoading = true;
        _error = null;
      });
    }

    try {
      final page = await widget.repository.load(widget.match.id);
      if (!mounted) return;

      setState(() {
        _participants = page.participants;
        _messages = page.messages;
        _hasMoreOlder = page.hasMoreOlder;
        _canSend = page.canSend;
        _initialLoading = false;
      });

      _pollTimer = Timer.periodic(_pollInterval, (_) => _pollNewMessages());
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _initialLoading = false;
        _error = _messageFor(error);
      });
    }
  }

  Future<void> _pollNewMessages() async {
    if (_pollInFlight || _initialLoading || !mounted) return;
    _pollInFlight = true;

    try {
      final afterId = _messages.isEmpty ? '0' : _messages.last.id;
      final page = await widget.repository.load(
        widget.match.id,
        afterId: afterId,
      );
      if (!mounted) return;

      final merged = _mergeMessages(_messages, page.messages);
      setState(() {
        _participants = page.participants;
        _messages = merged;
        _canSend = page.canSend;
      });
    } catch (_) {
      // Keep the current conversation visible. The next polling cycle retries.
    } finally {
      _pollInFlight = false;
    }
  }

  Future<void> _loadOlder() async {
    if (_loadingOlder || !_hasMoreOlder || _messages.isEmpty) return;

    setState(() => _loadingOlder = true);
    try {
      final page = await widget.repository.load(
        widget.match.id,
        beforeId: _messages.first.id,
      );
      if (!mounted) return;

      setState(() {
        _participants = page.participants;
        _messages = _mergeMessages(page.messages, _messages);
        _hasMoreOlder = page.hasMoreOlder;
        _canSend = page.canSend;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(_messageFor(error))));
      }
    } finally {
      if (mounted) setState(() => _loadingOlder = false);
    }
  }

  Future<void> _sendMessage(String matchId, String text) async {
    final message = await widget.repository.send(matchId, text);
    if (!mounted) return;

    setState(() {
      _messages = _mergeMessages(_messages, [message]);
    });
  }

  List<ChatMessage> _mergeMessages(
    List<ChatMessage> first,
    List<ChatMessage> second,
  ) {
    final byId = <String, ChatMessage>{};
    for (final message in [...first, ...second]) {
      byId[message.id] = message;
    }

    final merged = byId.values.toList(growable: false)
      ..sort((left, right) {
        final leftId = int.tryParse(left.id);
        final rightId = int.tryParse(right.id);
        if (leftId != null && rightId != null) {
          return leftId.compareTo(rightId);
        }
        return left.timestamp.compareTo(right.timestamp);
      });
    return merged;
  }

  String _messageFor(Object error) {
    if (error is ApiException) return error.message;
    return 'Could not load match chat. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return MatchChatScreen(
      match: widget.match,
      participants: _participants,
      messages: _messages,
      currentUserId: widget.currentUserId,
      currentUserAvatarAsset: AppAssets.bottomProfileIcon,
      currentUserAvatarUrl: widget.currentUserAvatarUrl,
      onBack: widget.onBack,
      onPlayerTap: widget.onPlayerTap,
      onSendMessage: _sendMessage,
      onLoadOlder: _loadOlder,
      onRetry: _loadInitial,
      isLoading: _initialLoading,
      isLoadingOlder: _loadingOlder,
      hasMoreOlder: _hasMoreOlder,
      canSend: _canSend,
      errorMessage: _error,
    );
  }
}
