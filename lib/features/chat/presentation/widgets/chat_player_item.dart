import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../domain/chat_models.dart';

class ChatPlayerItem extends StatelessWidget {
  const ChatPlayerItem({required this.participant, super.key, this.onTap});

  final ChatParticipant participant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final normalizedName = participant.displayName.trim();
    final firstName = normalizedName.isEmpty
        ? 'Player'
        : normalizedName.split(RegExp(r'\\s+')).first;

    final content = SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppAvatar(
                fallbackAsset: participant.avatarAsset,
                imageUrl: participant.avatarUrl,
                size: 40,
              ),
              if (participant.isOnline)
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: AppColors.matchSuccess,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            firstName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.homeMeta14.copyWith(color: AppColors.heading),
          ),
        ],
      ),
    );

    return Semantics(
      button: onTap != null,
      label: '$firstName${participant.isOnline ? ', online' : ''}',
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: content,
                ),
              ),
            ),
    );
  }
}
