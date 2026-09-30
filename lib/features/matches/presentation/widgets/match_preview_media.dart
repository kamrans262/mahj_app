import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../../app/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_asset_icon.dart';

class MatchPreviewMedia extends StatelessWidget {
  const MatchPreviewMedia({
    required this.hasLocationPreview,
    required this.sportImageAsset,
    super.key,
    this.latitude,
    this.longitude,
    this.markerNormalizedX,
    this.markerNormalizedY,
    this.markerSize = 44,
  });

  final bool hasLocationPreview;
  final String sportImageAsset;
  final double? latitude;
  final double? longitude;
  final double? markerNormalizedX;
  final double? markerNormalizedY;
  final double markerSize;

  bool get _hasLiveCoordinates => latitude != null && longitude != null;

  @override
  Widget build(BuildContext context) {
    if (!hasLocationPreview) {
      return _SportImage(assetPath: sportImageAsset);
    }

    if (_hasLiveCoordinates) {
      return _StaticLocationMap(
        latitude: latitude!,
        longitude: longitude!,
        markerSize: markerSize,
      );
    }

    final normalizedX = _normalized(markerNormalizedX ?? 0.5);
    final normalizedY = _normalized(markerNormalizedY ?? 0.5);

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        SvgPicture.asset(AppAssets.mapDemoBackground, fit: BoxFit.cover),
        Align(
          alignment: Alignment(normalizedX * 2 - 1, normalizedY * 2 - 1),
          child: AppAssetIcon(
            assetPath: AppAssets.mapMatchMarkerIcon,
            size: markerSize,
          ),
        ),
      ],
    );
  }

  double _normalized(double value) {
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }
}

class _StaticLocationMap extends StatelessWidget {
  const _StaticLocationMap({
    required this.latitude,
    required this.longitude,
    required this.markerSize,
  });

  final double latitude;
  final double longitude;
  final double markerSize;

  @override
  Widget build(BuildContext context) {
    final position = ll.LatLng(latitude, longitude);

    return IgnorePointer(
      child: fm.FlutterMap(
        options: fm.MapOptions(
          initialCenter: position,
          initialZoom: 16.5,
          minZoom: 16.5,
          maxZoom: 16.5,
          interactionOptions: const fm.InteractionOptions(
            flags: fm.InteractiveFlag.none,
          ),
          backgroundColor: AppColors.subtleSurface,
        ),
        children: [
          fm.TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.mahj_app',
          ),
          fm.MarkerLayer(
            markers: [
              fm.Marker(
                point: position,
                width: markerSize,
                height: markerSize,
                alignment: Alignment.center,
                child: Image.asset(
                  AppAssets.mapMatchMarkerPng,
                  width: markerSize,
                  height: markerSize,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ],
          ),
          const fm.RichAttributionWidget(
            attributions: [
              fm.TextSourceAttribution('OpenStreetMap'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SportImage extends StatelessWidget {
  const _SportImage({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        return ColoredBox(
          color: AppColors.subtleSurface,
          child: Center(
            child: AppAssetIcon(
              assetPath: AppAssets.homeFootballIcon,
              size: 40,
              color: AppColors.primary,
            ),
          ),
        );
      },
    );
  }
}
