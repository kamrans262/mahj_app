import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../data/chat_repository.dart';
import '../domain/chat_models.dart';
import 'direct_chat_screen.dart';

class ConnectedDirectChatScreen extends StatefulWidget {
  const ConnectedDirectChatScreen({
    required this.conversation,
    required this.repository,
    required this.currentUserId,
    super.key,
    this.onBack,
  });

  final DirectChatSummary conversation;
  final ChatRepository repository;
  final String currentUserId;
  final VoidCallback? onBack;

  @override
  State<ConnectedDirectChatScreen> createState() =>
      _ConnectedDirectChatScreenState();
}

class _ConnectedDirectChatScreenState extends State<ConnectedDirectChatScreen> {
  static const Duration _pollInterval = Duration(seconds: 4);

  List<ChatMessage> _messages = const [];
  bool _initialLoading = true;
  bool _loadingOlder = false;
  bool _hasMoreOlder = false;
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
      final page = await widget.repository.loadDirect(
        widget.conversation.id,
      );
      if (!mounted) return;

      setState(() {
        _messages = page.messages;
        _hasMoreOlder = page.hasMoreOlder;
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
      final page = await widget.repository.loadDirect(
        widget.conversation.id,
        afterId: afterId,
      );
      if (!mounted) return;

      setState(() {
        _messages = _mergeMessages(_messages, page.messages);
      });
    } catch (_) {
      // The next polling cycle retries.
    } finally {
      _pollInFlight = false;
    }
  }

  Future<void> _loadOlder() async {
    if (_loadingOlder || !_hasMoreOlder || _messages.isEmpty) return;

    setState(() => _loadingOlder = true);
    try {
      final page = await widget.repository.loadDirect(
        widget.conversation.id,
        beforeId: _messages.first.id,
      );
      if (!mounted) return;

      setState(() {
        _messages = _mergeMessages(page.messages, _messages);
        _hasMoreOlder = page.hasMoreOlder;
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

  Future<void> _sendMessage(String text) async {
    final message = await widget.repository.sendDirect(
      widget.conversation.id,
      text,
    );
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
    return 'Could not load this chat. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return DirectChatScreen(
      participant: widget.conversation.participant,
      messages: _messages,
      currentUserId: widget.currentUserId,
      onBack: widget.onBack,
      onSendMessage: _sendMessage,
      onLoadOlder: _loadOlder,
      onRetry: _loadInitial,
      isLoading: _initialLoading,
      isLoadingOlder: _loadingOlder,
      hasMoreOlder: _hasMoreOlder,
      errorMessage: _error,
    );
  }
}
