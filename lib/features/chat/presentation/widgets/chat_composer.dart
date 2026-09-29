import 'package:flutter/material.dart';

import '../../../../app/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_icon_action_button.dart';
import '../../../../core/widgets/app_surface_container.dart';

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    required this.controller,
    required this.onSend,
    super.key,
    this.focusNode,
    this.isSending = false,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback? onSend;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: AppSurfaceContainer(
            minHeight: AppIconActionButton.size,
            padding: EdgeInsets.zero,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              minLines: 1,
              maxLines: 4,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              style: AppTypography.homeMeta14.copyWith(
                color: AppColors.heading,
              ),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: 'Type a message....',
                hintStyle: AppTypography.homeMeta14,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppIconActionButton(
          assetPath: AppAssets.chatSendIcon,
          onPressed: isSending ? null : onSend,
          isLoading: isSending,
          semanticLabel: 'Send message',
        ),
      ],
    );
  }
}
