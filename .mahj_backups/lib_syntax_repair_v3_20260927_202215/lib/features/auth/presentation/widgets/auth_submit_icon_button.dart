import 'package:flutter/material.dart';

import '../../../../core/widgets/app_icon_action_button.dart';

class AuthSubmitIconButton extends StatelessWidget {
  const AuthSubmitIconButton({
    required this.onPressed,
    super.key,
    this.assetPath,
    this.isLoading = false,
    this.semanticLabel = 'Send reset link',
  });

  final VoidCallback? onPressed;
  final String? assetPath;
  final bool isLoading;
  final String semanticLabel;

  static const double size = AppIconActionButton.size;

  @override
  Widget build(BuildContext context) {
    return AppIconActionButton(
      onPressed: onPressed,
      assetPath: assetPath,
      isLoading: isLoading,
      semanticLabel: semanticLabel,
      iconKey: const ValueKey('forgot-send-icon'),
    );
  }
}
