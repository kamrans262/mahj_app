import 'package:flutter/material.dart';

import '../../../../app/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_surface_container.dart';
import '../../domain/chat_models.dart';
import 'system_chat_message.dart';

class ChatMessageItem extends StatelessWidget {
  const ChatMessageItem({
    required this.message,
    required this.currentUserId,
    super.key,
  });

  final ChatMessage message;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    if (message.type == ChatMessageType.system) {
      return SystemChatMessage(text: message.text);
    }

    final isMine = message.isMine(currentUserId);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBubbleWidth = constraints.maxWidth * 0.76;
        return isMine
            ? _OutgoingMessage(message: message, maxBubbleWidth: maxBubbleWidth)
            : _IncomingMessage(
                message: message,
                maxBubbleWidth: maxBubbleWidth,
              );
      },
    );
  }
}

class _IncomingMessage extends StatelessWidget {
  const _IncomingMessage({required this.message, required this.maxBubbleWidth});

  final ChatMessage message;
  final double maxBubbleWidth;

  @override
  Widget build(BuildContext context) {
    final senderName = message.senderName?.trim().isNotEmpty == true
        ? message.senderName!
        : 'Player';

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppAvatar(
                fallbackAsset:
                    message.senderAvatarAsset ?? AppAssets.bottomProfileIcon,
                imageUrl: message.senderAvatarUrl,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.micro),
              Flexible(
                child: Text(
                  senderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.homeMeta14,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.micro),
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  child: AppSurfaceContainer(
                    minHeight: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      message.text,
                      style: AppTypography.homeMeta14,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatTime(message.timestamp),
                  style: AppTypography.homeMeta14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutgoingMessage extends StatelessWidget {
  const _OutgoingMessage({required this.message, required this.maxBubbleWidth});

  final ChatMessage message;
  final double maxBubbleWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_formatTime(message.timestamp), style: AppTypography.homeMeta14),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                child: AppSurfaceContainer(
                  minHeight: 0,
                  backgroundColor: AppColors.primary,
                  borderColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text(
                    message.text,
                    style: AppTypography.homeMeta14.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AppAvatar(
                fallbackAsset:
                    message.senderAvatarAsset ?? AppAssets.bottomProfileIcon,
                imageUrl: message.senderAvatarUrl,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}
