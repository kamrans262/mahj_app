import 'package:flutter/material.dart';

import '../../../../app/theme/app_typography.dart';

class AuthInlineActionPrompt extends StatelessWidget {
  const AuthInlineActionPrompt({
    required this.message,
    required this.actionLabel,
    required this.enabled,
    super.key,
    this.actionKey,
    this.onAction,
  });

  final String message;
  final String actionLabel;
  final bool enabled;
  final Key? actionKey;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(message, style: AppTypography.body14),
        InkWell(
          key: actionKey,
          onTap: enabled && onAction != null ? onAction : null,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(actionLabel, style: AppTypography.action14),
          ),
        ),
      ],
    );
  }
}
