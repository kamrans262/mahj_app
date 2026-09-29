import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class SuccessCelebration extends StatefulWidget {
  const SuccessCelebration({
    super.key,
    this.successColor = AppColors.matchSuccess,
    this.dotColors = const [
      Color(0xFFEC5D01),
      Color(0xFFDC4D89),
      Color(0xFF9254C8),
      Color(0xFF4184D7),
      Color(0xFFE8B33E),
      Color(0xFF76CDD1),
    ],
  });

  final Color successColor;
  final List<Color> dotColors;

  @override
  State<SuccessCelebration> createState() => _SuccessCelebrationState();
}

class _SuccessCelebrationState extends State<SuccessCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _dotOffsets = <Offset>[
    Offset(-96, -34),
    Offset(-62, -82),
    Offset(18, -92),
    Offset(82, -62),
    Offset(102, 8),
    Offset(70, 78),
    Offset(10, 100),
    Offset(-58, 80),
    Offset(-98, 36),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _circleScale(double t) {
    if (t <= 0.72) {
      return lerpDouble(0.70, 1.06, t / 0.72)!;
    }
    return lerpDouble(1.06, 1, (t - 0.72) / 0.28)!;
  }

  double _checkProgress(double t) {
    return ((t - 0.20) / 0.45).clamp(0.0, 1.0);
  }

  double _dotProgress(double t) {
    return ((t - 0.04) / 0.72).clamp(0.0, 1.0);
  }

  double _dotOpacity(double progress) {
    if (progress <= 0.20) {
      return progress / 0.20;
    }
    if (progress <= 0.68) {
      return 1;
    }
    return (1 - ((progress - 0.68) / 0.32)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Match created successfully',
      child: ExcludeSemantics(
        child: SizedBox(
          width: 220,
          height: 220,
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = Curves.easeOutCubic.transform(_controller.value);
                final dotProgress = _dotProgress(t);
                final dotOpacity = _dotOpacity(dotProgress);
                final checkProgress = _checkProgress(t);

                return Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    for (var index = 0; index < _dotOffsets.length; index++)
                      Transform.translate(
                        offset: Offset.lerp(
                          _dotOffsets[index] * 0.18,
                          _dotOffsets[index],
                          dotProgress,
                        )!,
                        child: Opacity(
                          opacity: dotOpacity,
                          child: Transform.scale(
                            scale: lerpDouble(0.55, 1, dotProgress)!,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: widget
                                    .dotColors[index % widget.dotColors.length],
                                shape: BoxShape.circle,
                              ),
                              child: const SizedBox.square(dimension: 6),
                            ),
                          ),
                        ),
                      ),
                    Transform.scale(
                      scale: _circleScale(t),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: widget.successColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Opacity(
                            opacity: checkProgress,
                            child: Transform.scale(
                              scale: lerpDouble(0.72, 1, checkProgress)!,
                              child: const Icon(
                                Icons.check_rounded,
                                size: 58,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
