import 'package:flutter/material.dart';

import 'app_asset_icon.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    required this.fallbackAsset,
    super.key,
    this.imageUrl,
    this.size = 40,
  });

  final String fallbackAsset;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = imageUrl?.trim();

    Widget fallback() => AppAssetIcon(assetPath: fallbackAsset, size: size);

    return Semantics(
      image: true,
      label: 'Profile photo',
      child: ClipOval(
        child: SizedBox.square(
          dimension: size,
          child: normalizedUrl == null || normalizedUrl.isEmpty
              ? fallback()
              : Image.network(
                  normalizedUrl,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, _, _) => fallback(),
                ),
        ),
      ),
    );
  }
}
