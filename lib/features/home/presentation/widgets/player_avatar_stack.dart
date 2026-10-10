import 'package:flutter/material.dart';

import '../../../../app/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_asset_icon.dart';

class PlayerAvatarStack extends StatelessWidget {
  const PlayerAvatarStack({
    this.assetPaths = const <String>[],
    this.imageUrls = const <String?>[],
    super.key,
    this.size = 28,
    this.overlap = 8,
    this.maxVisible = 3,
  });

  final List<String> assetPaths;
  final List<String?> imageUrls;
  final double size;
  final double overlap;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final useNetworkAvatars = imageUrls.isNotEmpty;
    final visibleCount = useNetworkAvatars
        ? imageUrls.take(maxVisible).length
        : assetPaths.take(maxVisible).length;

    if (visibleCount == 0) {
      return const SizedBox.shrink();
    }

    final step = size - overlap;
    final width = size + (visibleCount - 1) * step;

    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var index = 0; index < visibleCount; index++)
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
                    child: useNetworkAvatars
                        ? _NetworkPlayerAvatar(
                            imageUrl: imageUrls[index],
                            size: size - 2,
                          )
                        : AppAssetIcon(
                            assetPath: assetPaths[index],
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

class _NetworkPlayerAvatar extends StatelessWidget {
  const _NetworkPlayerAvatar({required this.imageUrl, required this.size});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();

    Widget fallback() {
      return ColoredBox(
        color: AppColors.subtleSurface,
        child: Center(
          child: AppAssetIcon(
            assetPath: AppAssets.bottomProfileIcon,
            size: size * 0.58,
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (url == null || url.isEmpty) {
      return fallback();
    }

    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) => fallback(),
    );
  }
}
