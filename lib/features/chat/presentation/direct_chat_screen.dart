import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_loader.dart';
import '../domain/chat_models.dart';
import 'widgets/chat_composer.dart';
import 'widgets/chat_message_item.dart';

typedef DirectChatSendCallback = Future<void> Function(String text);
typedef DirectChatLoadOlderCallback = Future<void> Function();

class DirectChatScreen extends StatefulWidget {
  const DirectChatScreen({
    required this.participant,
    required this.messages,
    required this.currentUserId,
    super.key,
    this.onBack,
    this.onSendMessage,
    this.onLoadOlder,
    this.onRetry,
    this.isLoading = false,
    this.isLoadingOlder = false,
    this.hasMoreOlder = false,
    this.errorMessage,
  });

  final ChatParticipant participant;
  final List<ChatMessage> messages;
  final String currentUserId;
  final VoidCallback? onBack;
  final DirectChatSendCallback? onSendMessage;
  final DirectChatLoadOlderCallback? onLoadOlder;
  final VoidCallback? onRetry;
  final bool isLoading;
  final bool isLoadingOlder;
  final bool hasMoreOlder;
  final String? errorMessage;

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final TextEditingController _composerController = TextEditingController();
  final FocusNode _composerFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  bool _sending = false;
  bool _requestingOlder = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
  }

  @override
  void didUpdateWidget(covariant DirectChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _composerController.dispose();
    _composerFocusNode.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients ||
        _scrollController.position.pixels > 80 ||
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
        !_scrollController.hasClients) {
      return;
    }

    _requestingOlder = true;
    final position = _scrollController.position;
    final oldPixels = position.pixels;
    final oldMaxExtent = position.maxScrollExtent;

    try {
      await callback();
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final newMaxExtent = _scrollController.position.maxScrollExtent;
        final target = (oldPixels + newMaxExtent - oldMaxExtent).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );
        _scrollController.jumpTo(target);
      });
    } finally {
      _requestingOlder = false;
    }
  }

  Future<void> _send() async {
    if (_sending || widget.onSendMessage == null) return;

    final text = _composerController.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      await widget.onSendMessage!(text);
      if (!mounted) return;
      _composerController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not send the message. Please try again.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return position.maxScrollExtent - position.pixels <= 120;
  }

  void _scrollToLatest() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
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
                  onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageHorizontal,
                ),
                child: Row(
                  children: [
                    AppAvatar(
                      fallbackAsset: widget.participant.avatarAsset.isEmpty
                          ? AppAssets.bottomProfileIcon
                          : widget.participant.avatarAsset,
                      imageUrl: widget.participant.avatarUrl,
                      size: 44,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        widget.participant.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.homeMatchTitle16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (widget.isLoading && widget.messages.isEmpty) {
      return const Center(child: AppLoader());
    }

    if (widget.errorMessage != null && widget.messages.isEmpty) {
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
        0,
        AppSpacing.pageHorizontal,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          Expanded(
            child: widget.messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet',
                      style: AppTypography.homeMeta14,
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    itemCount:
                        widget.messages.length + (widget.isLoadingOlder ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.lg),
                    itemBuilder: (context, index) {
                      if (widget.isLoadingOlder && index == 0) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          child: Center(child: AppLoader()),
                        );
                      }

                      final messageIndex = widget.isLoadingOlder
                          ? index - 1
                          : index;
                      return ChatMessageItem(
                        message: widget.messages[messageIndex],
                        currentUserId: widget.currentUserId,
                      );
                    },
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ChatComposer(
            controller: _composerController,
            focusNode: _composerFocusNode,
            isSending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}
