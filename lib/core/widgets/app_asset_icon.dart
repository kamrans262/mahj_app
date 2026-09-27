import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppAssetIcon extends StatelessWidget {
  const AppAssetIcon({required this.assetPath, super.key, this.size = 24});

  final String assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isSvg = assetPath.toLowerCase().endsWith('.svg');

    return SizedBox.square(
      dimension: size,
      child: isSvg
          ? SvgPicture.asset(
              assetPath,
              width: size,
              height: size,
              fit: BoxFit.contain,
            )
          : Image.asset(
              assetPath,
              width: size,
              height: size,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
    );
  }
}
