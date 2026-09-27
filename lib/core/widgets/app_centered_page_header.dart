import 'package:flutter/material.dart';

import '../../app/theme/app_typography.dart';
import 'app_back_button.dart';

class AppCenteredPageHeader extends StatelessWidget {
  const AppCenteredPageHeader({
    required this.title,
    required this.onBack,
    super.key,
  });

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppBackButton.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: AppBackButton(onPressed: onBack),
          ),
          IgnorePointer(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.homeGreeting,
            ),
          ),
        ],
      ),
    );
  }
}
