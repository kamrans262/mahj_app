import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../home/domain/home_match.dart';
import '../domain/chat_models.dart';
import 'widgets/chat_composer.dart';
import 'widgets/chat_message_item.dart';
import 'widgets/chat_player_item.dart';

typedef ChatSendCallback = Future<ChatMessage> Function(
  String matchId,
  String text,
);
typedef ChatPlayerTapCallback = void Function(ChatParticipant participant);

class MatchChatScreen extends StatefulWidget {
  const MatchChatScreen({
    required this.match,
    required this.participants,
    required this.messages,
    required this.currentUserId,
    super.key,
    this.currentUserAvatarAsset = AppAssets.demoAvatarOne,
    this.onBack,
    this.onSendMessage,
    this.onPlayerTap,
  });

  final HomeMatch match;
  final List<ChatParticipant> participants;
  final List<ChatMessage> messages;
  final String currentUserId;
  final String currentUserAvatarAsset;
  final VoidCallback? onBack;
  final ChatSendCallback? onSendMessage;
  final ChatPlayerTapCallback? onPlayerTap;

  @override
  State<MatchChatScreen> createState() => _MatchChatScreenState();
}

class _MatchChatScreenState extends State<MatchChatScreen> {
  final TextEditingController _composerController = TextEditingController();
  final FocusNode _composerFocusNode = FocusNode();
  final ScrollController _messageScrollController = ScrollController();

  late List<ChatMessage> _messages;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messages = List<ChatMessage>.of(widget.messages);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
  }

  @override
  void didUpdateWidget(covariant MatchChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.messages, widget.messages) &&
        oldWidget.messages != widget.messages &&
        !_isSending) {
      _messages = List<ChatMessage>.of(widget.messages);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
    }
  }

  @override
  void dispose() {
    _composerController.dispose();
    _composerFocusNode.dispose();
    _messageScrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;

    final text = _composerController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final callback = widget.onSendMessage;
      final message = callback != null
          ? await callback(widget.match.id, text)
          : ChatMessage(
              id: 'local-${DateTime.now().microsecondsSinceEpoch}',
              matchId: widget.match.id,
              senderId: widget.currentUserId,
              senderName: 'You',
              senderAvatarAsset: widget.currentUserAvatarAsset,
              text: text,
              timestamp: DateTime.now(),
              type: ChatMessageType.message,
            );

      if (!mounted) return;

      setState(() {
        _messages = [..._messages, message];
        _composerController.clear();
      });

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
                  title: 'Match Chat',
                  onBack:
                      widget.onBack ?? () => Navigator.of(context).maybePop(),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    30,
                    AppSpacing.pageHorizontal,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Chat Players',
                        style: AppTypography.homeSectionHeading,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        height: 74,
                        child: ListView.separated(
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
                      ChatComposer(
                        controller: _composerController,
                        focusNode: _composerFocusNode,
                        isSending: _isSending,
                        onSend: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
      itemCount: _messages.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, index) {
        return ChatMessageItem(
          message: _messages[index],
          currentUserId: widget.currentUserId,
        );
      },
    );
  }
}
