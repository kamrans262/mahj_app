import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AppLoader extends StatelessWidget {
  const AppLoader({
    super.key,
    this.size = 40,
    this.strokeWidth = 4,
    this.color = AppColors.primary,
  });

  final double size;
  final double strokeWidth;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        strokeCap: StrokeCap.round,
        color: color,
      ),
    );
  }
}
