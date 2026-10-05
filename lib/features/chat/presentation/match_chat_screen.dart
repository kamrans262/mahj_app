import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_loader.dart';
import '../../home/domain/home_match.dart';
import '../../home/presentation/home_date_time_formatter.dart';
import '../domain/chat_models.dart';
import 'widgets/chat_composer.dart';
import 'widgets/chat_message_item.dart';
import 'widgets/chat_player_item.dart';

typedef ChatSendCallback = Future<void> Function(String matchId, String text);
typedef ChatPlayerTapCallback = void Function(ChatParticipant participant);
typedef ChatLoadOlderCallback = Future<void> Function();

class MatchChatScreen extends StatefulWidget {
  const MatchChatScreen({
    required this.match,
    required this.participants,
    required this.messages,
    required this.currentUserId,
    super.key,
    this.currentUserAvatarAsset = AppAssets.bottomProfileIcon,
    this.currentUserAvatarUrl,
    this.onBack,
    this.onSendMessage,
    this.onPlayerTap,
    this.onLoadOlder,
    this.onRetry,
    this.isLoading = false,
    this.isLoadingOlder = false,
    this.hasMoreOlder = false,
    this.canSend = true,
    this.errorMessage,
  });

  final HomeMatch match;
  final List<ChatParticipant> participants;
  final List<ChatMessage> messages;
  final String currentUserId;
  final String currentUserAvatarAsset;
  final String? currentUserAvatarUrl;
  final VoidCallback? onBack;
  final ChatSendCallback? onSendMessage;
  final ChatPlayerTapCallback? onPlayerTap;
  final ChatLoadOlderCallback? onLoadOlder;
  final VoidCallback? onRetry;
  final bool isLoading;
  final bool isLoadingOlder;
  final bool hasMoreOlder;
  final bool canSend;
  final String? errorMessage;

  @override
  State<MatchChatScreen> createState() => _MatchChatScreenState();
}

class _MatchChatScreenState extends State<MatchChatScreen> {
  final TextEditingController _composerController = TextEditingController();
  final FocusNode _composerFocusNode = FocusNode();
  final ScrollController _messageScrollController = ScrollController();

  late List<ChatMessage> _previewMessages;
  bool _isSending = false;
  bool _requestingOlder = false;

  List<ChatMessage> get _messages =>
      widget.onSendMessage == null ? _previewMessages : widget.messages;

  @override
  void initState() {
    super.initState();
    _previewMessages = List<ChatMessage>.of(widget.messages);
    _messageScrollController.addListener(_handleMessageScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
  }

  @override
  void didUpdateWidget(covariant MatchChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.onSendMessage == null && oldWidget.messages != widget.messages) {
      _previewMessages = List<ChatMessage>.of(widget.messages);
    }

    if (oldWidget.messages.isEmpty && widget.messages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
      return;
    }

    if (oldWidget.messages.isNotEmpty &&
        widget.messages.isNotEmpty &&
        oldWidget.messages.last.id != widget.messages.last.id &&
        _isNearBottom()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
    }
  }

  @override
  void dispose() {
    _messageScrollController
      ..removeListener(_handleMessageScroll)
      ..dispose();
    _composerController.dispose();
    _composerFocusNode.dispose();
    super.dispose();
  }

  void _handleMessageScroll() {
    if (!_messageScrollController.hasClients ||
        _messageScrollController.position.pixels > 80 ||
        !widget.hasMoreOlder ||
        widget.isLoadingOlder ||
        _requestingOlder ||
        widget.onLoadOlder == null) {
      return;
    }

    _loadOlder();
  }

  Future<void> _loadOlder() async {
    final callback = widget.onLoadOlder;
    if (callback == null ||
        _requestingOlder ||
        widget.isLoadingOlder ||
        !widget.hasMoreOlder ||
        !_messageScrollController.hasClients) {
      return;
    }

    _requestingOlder = true;
    final position = _messageScrollController.position;
    final oldPixels = position.pixels;
    final oldMaxExtent = position.maxScrollExtent;

    try {
      await callback();
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_messageScrollController.hasClients) return;
        final newMaxExtent = _messageScrollController.position.maxScrollExtent;
        final delta = newMaxExtent - oldMaxExtent;
        final target = (oldPixels + delta).clamp(
          0.0,
          _messageScrollController.position.maxScrollExtent,
        );
        _messageScrollController.jumpTo(target);
      });
    } finally {
      _requestingOlder = false;
    }
  }

  Future<void> _sendMessage() async {
    if (_isSending || !widget.canSend) return;

    final text = _composerController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final callback = widget.onSendMessage;
      if (callback != null) {
        await callback(widget.match.id, text);
      } else {
        final message = ChatMessage(
          id: 'local-${DateTime.now().microsecondsSinceEpoch}',
          matchId: widget.match.id,
          senderId: widget.currentUserId,
          senderName: 'You',
          senderAvatarAsset: widget.currentUserAvatarAsset,
          senderAvatarUrl: widget.currentUserAvatarUrl,
          text: text,
          timestamp: DateTime.now(),
          type: ChatMessageType.message,
        );
        _previewMessages = [..._previewMessages, message];
      }

      if (!mounted) return;
      _composerController.clear();
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Could not send the message. Please try again.'),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  bool _isNearBottom() {
    if (!_messageScrollController.hasClients) return true;
    final position = _messageScrollController.position;
    return position.maxScrollExtent - position.pixels <= 120;
  }

  void _scrollToLatest() {
    if (!_messageScrollController.hasClients) return;

    final position = _messageScrollController.position;
    _messageScrollController.animateTo(
      position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
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
                  title: 'Chat',
                  onBack:
                      widget.onBack ?? () => Navigator.of(context).maybePop(),
                ),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (widget.isLoading && widget.participants.isEmpty && _messages.isEmpty) {
      return const Center(child: AppLoader());
    }

    if (widget.errorMessage != null &&
        widget.participants.isEmpty &&
        _messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.body14,
              ),
              if (widget.onRetry != null) ...[
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: widget.onRetry,
                  child: Text('Retry', style: AppTypography.action14),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        30,
        AppSpacing.pageHorizontal,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Chat Players', style: AppTypography.homeSectionHeading),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${HomeDateTimeFormatter.compactDate(widget.match.startsAt)} · '
                    '${HomeDateTimeFormatter.time(widget.match.startsAt)}',
                    textAlign: TextAlign.right,
                    style: AppTypography.homeMeta14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 74,
            child: widget.participants.isEmpty
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'No players available',
                      style: AppTypography.homeMeta14,
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.participants.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final participant = widget.participants[index];
                      return ChatPlayerItem(
                        participant: participant,
                        onTap: widget.onPlayerTap == null
                            ? null
                            : () => widget.onPlayerTap!(participant),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 25),
          Expanded(child: _buildMessageList()),
          const SizedBox(height: AppSpacing.sm),
          if (widget.canSend)
            ChatComposer(
              controller: _composerController,
              focusNode: _composerFocusNode,
              isSending: _isSending,
              onSend: _sendMessage,
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'Chat is no longer available for this match.',
                textAlign: TextAlign.center,
                style: AppTypography.homeMeta14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Text('No messages yet', style: AppTypography.homeMeta14),
      );
    }

    return ListView.separated(
      controller: _messageScrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      itemCount: _messages.length + (widget.isLoadingOlder ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, index) {
        if (widget.isLoadingOlder && index == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Center(child: AppLoader()),
          );
        }

        final messageIndex = widget.isLoadingOlder ? index - 1 : index;
        return ChatMessageItem(
          message: _messages[messageIndex],
          currentUserId: widget.currentUserId,
        );
      },
    );
  }
}
