import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class AuthBackground extends StatelessWidget {
  const AuthBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [const AuthBackgroundGlow(), child],
    );
  }
}

class AuthBackgroundGlow extends StatelessWidget {
  const AuthBackgroundGlow({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final glowWidth = math.min(429.0, math.max(320.0, screenWidth * 1.1));
    final glowHeight = glowWidth * (273 / 429);

    return IgnorePointer(
      child: Align(
        alignment: Alignment.topRight,
        child: Transform.translate(
          offset: Offset(glowWidth * 0.34, -glowHeight * 0.50),
          child: Container(
            width: glowWidth,
            height: glowHeight,
            decoration: BoxDecoration(
              color: AppColors.authGlow,
              borderRadius: BorderRadius.circular(glowWidth),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.authGlow,
                  blurRadius: 200,
                  spreadRadius: 30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
