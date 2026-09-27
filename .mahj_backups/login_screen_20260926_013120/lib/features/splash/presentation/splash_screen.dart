import 'package:flutter/material.dart';

import '../../../core/widgets/app_loader.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const _logoAsset = 'assets/splash_logo.png';
  static const _logoToLoaderGap = 35.0;
  static const _logoWidthFactor = 0.52;
  static const _minimumLogoWidth = 180.0;
  static const _maximumLogoWidth = 280.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final logoWidth = (constraints.maxWidth * _logoWidthFactor)
                  .clamp(_minimumLogoWidth, _maximumLogoWidth)
                  .toDouble();

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    _logoAsset,
                    key: const ValueKey('splash-logo'),
                    width: logoWidth,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                  const SizedBox(height: _logoToLoaderGap),
                  const AppLoader(key: ValueKey('splash-loader')),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
