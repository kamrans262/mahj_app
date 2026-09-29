import 'package:flutter/material.dart';

import '../../../../core/widgets/app_asset_icon.dart';

class PlayerAvatarStack extends StatelessWidget {
  const PlayerAvatarStack({
    required this.assetPaths,
    super.key,
    this.size = 28,
    this.overlap = 8,
    this.maxVisible = 3,
  });

  final List<String> assetPaths;
  final double size;
  final double overlap;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final visible = assetPaths.take(maxVisible).toList(growable: false);

    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }

    final step = size - overlap;
    final width = size + (visible.length - 1) * step;

    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var index = 0; index < visible.length; index++)
              Positioned(
                left: index * step,
                child: Container(
                  width: size,
                  height: size,
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: ClipOval(
                    child: AppAssetIcon(
                      assetPath: visible[index],
                      size: size - 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
