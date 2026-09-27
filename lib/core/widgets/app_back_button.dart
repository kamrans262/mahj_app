import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({
    required this.onPressed,
    super.key,
    this.semanticLabel = 'Back',
  });

  final VoidCallback? onPressed;
  final String semanticLabel;

  static const double size = 40;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.navigationButtonBackground,
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(color: AppColors.navigationButtonBorder),
            boxShadow: const [
              BoxShadow(
                color: AppColors.navigationButtonShadow,
                offset: Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: BorderRadius.circular(AppRadius.control),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: AppColors.heading,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
