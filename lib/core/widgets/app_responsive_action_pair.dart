import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';

class AppResponsiveActionPair extends StatelessWidget {
  const AppResponsiveActionPair({
    required this.first,
    required this.second,
    super.key,
    this.horizontalGap = AppSpacing.lg,
    this.verticalGap = AppSpacing.sm,
  });

  final Widget first;
  final Widget second;
  final double horizontalGap;
  final double verticalGap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final shouldStack = constraints.maxWidth < 300 || textScale > 1.35;

        if (shouldStack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              first,
              SizedBox(height: verticalGap),
              second,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: first),
            SizedBox(width: horizontalGap),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}
