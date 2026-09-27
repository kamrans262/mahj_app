import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppAssetIcon extends StatelessWidget {
  const AppAssetIcon({
    required this.assetPath,
    super.key,
    this.size = 24,
    this.color,
  });

  final String assetPath;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isSvg = assetPath.toLowerCase().endsWith('.svg');
    final colorFilter = color == null
        ? null
        : ColorFilter.mode(color!, BlendMode.srcIn);

    return SizedBox.square(
      dimension: size,
      child: isSvg
          ? SvgPicture.asset(
              assetPath,
              width: size,
              height: size,
              fit: BoxFit.contain,
              colorFilter: colorFilter,
            )
          : Image.asset(
              assetPath,
              width: size,
              height: size,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              color: color,
              colorBlendMode: color == null ? null : BlendMode.srcIn,
            ),
    );
  }
}
