import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/maps/mahj_google_marker.dart';
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
    return _buildGoogleMap();
  }

  Widget _buildGoogleMap() {
    final position = gm.LatLng(latitude, longitude);

    return FutureBuilder<gm.BitmapDescriptor>(
      future: MahjGoogleMarker.load(
        width: markerSize,
        height: markerSize,
      ),
      builder: (context, snapshot) {
        final markerIcon =
            snapshot.data ??
            gm.BitmapDescriptor.defaultMarkerWithHue(
              gm.BitmapDescriptor.hueOrange,
            );

        return IgnorePointer(
          child: gm.GoogleMap(
            initialCameraPosition: gm.CameraPosition(
              target: position,
              zoom: 16.5,
            ),
            markers: {
              gm.Marker(
                markerId: gm.MarkerId(
                  'my-match-preview-${latitude.toStringAsFixed(6)}-'
                  '${longitude.toStringAsFixed(6)}',
                ),
                position: position,
                icon: markerIcon,
                anchor: const Offset(0.5, 0.5),
              ),
            },
            mapType: gm.MapType.normal,
            liteModeEnabled: true,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            compassEnabled: false,
            scrollGesturesEnabled: false,
            zoomGesturesEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
          ),
        );
      },
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
