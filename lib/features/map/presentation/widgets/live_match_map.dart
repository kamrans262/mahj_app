import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart' as ll;

import '../../../../app/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../home/presentation/home_date_time_formatter.dart';
import '../../domain/map_match_marker.dart';

class LiveMatchMap extends StatelessWidget {
  const LiveMatchMap({
    required this.markers,
    required this.selectedMatchId,
    required this.onMarkerTap,
    super.key,
    this.centerLatitude,
    this.centerLongitude,
    this.currentLocationLatitude,
    this.currentLocationLongitude,
  });

  static const String _mapProvider = String.fromEnvironment(
    'MAP_PROVIDER',
    defaultValue: 'osm',
  );

  final List<MapMatchMarker> markers;
  final String? selectedMatchId;
  final ValueChanged<MapMatchMarker> onMarkerTap;
  final double? centerLatitude;
  final double? centerLongitude;
  final double? currentLocationLatitude;
  final double? currentLocationLongitude;

  ({double latitude, double longitude}) get _initialCenter {
    if (centerLatitude != null && centerLongitude != null) {
      return (latitude: centerLatitude!, longitude: centerLongitude!);
    }

    for (final marker in markers) {
      final latitude = marker.match.latitude;
      final longitude = marker.match.longitude;
      if (latitude != null && longitude != null) {
        return (latitude: latitude, longitude: longitude);
      }
    }

    return (latitude: 30.1575, longitude: 71.5249);
  }

  bool get _useGoogleMaps => _mapProvider.toLowerCase() == 'google';

  @override
  Widget build(BuildContext context) {
    return _useGoogleMaps ? _buildGoogleMap() : _buildOpenStreetMap();
  }

  Widget _buildOpenStreetMap() {
    final center = _initialCenter;
    final mapMarkers = <fm.Marker>[];

    if (currentLocationLatitude != null && currentLocationLongitude != null) {
      mapMarkers.add(
        fm.Marker(
          point: ll.LatLng(
            currentLocationLatitude!,
            currentLocationLongitude!,
          ),
          width: 58,
          height: 58,
          child: const _CurrentLocationMarker(),
        ),
      );
    }

    for (final marker in markers) {
      final latitude = marker.match.latitude;
      final longitude = marker.match.longitude;
      if (latitude == null || longitude == null) continue;

      mapMarkers.add(
        fm.Marker(
          point: ll.LatLng(latitude, longitude),
          width: 150,
          height: 132,
          alignment: const Alignment(0, -0.12),
          child: GestureDetector(
            key: ValueKey('map-marker-${marker.match.id}'),
            behavior: HitTestBehavior.opaque,
            onTap: () => onMarkerTap(marker),
            child: _MatchMapPin(
              marker: marker,
              selected: marker.match.id == selectedMatchId,
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: fm.FlutterMap(
        options: fm.MapOptions(
          initialCenter: ll.LatLng(center.latitude, center.longitude),
          initialZoom: 13,
          minZoom: 3,
          maxZoom: 18,
          backgroundColor: const Color(0xFFFFFCF8),
        ),
        children: [
          fm.TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.mahj_app',
            tileBuilder: _styledOsmTile,
          ),
          fm.MarkerLayer(markers: mapMarkers),
          const fm.RichAttributionWidget(
            attributions: [
              fm.TextSourceAttribution('OpenStreetMap contributors'),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _styledOsmTile(
    BuildContext context,
    Widget tileWidget,
    fm.TileImage tile,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.72, 0, 0, 0, 64,
            0, 0.72, 0, 0, 62,
            0, 0, 0.72, 0, 58,
            0, 0, 0, 1, 0,
          ]),
          child: tileWidget,
        ),
        const ColoredBox(color: Color(0x0DEC5D01)),
      ],
    );
  }

  Widget _buildGoogleMap() {
    final center = _initialCenter;
    final googleMarkers = <gm.Marker>{};

    if (currentLocationLatitude != null && currentLocationLongitude != null) {
      googleMarkers.add(
        gm.Marker(
          markerId: const gm.MarkerId('current-location'),
          position: gm.LatLng(
            currentLocationLatitude!,
            currentLocationLongitude!,
          ),
          zIndexInt: 3,
          icon: gm.BitmapDescriptor.defaultMarkerWithHue(
            gm.BitmapDescriptor.hueAzure,
          ),
          infoWindow: const gm.InfoWindow(title: 'Current Location'),
        ),
      );
    }

    for (final marker in markers) {
      final latitude = marker.match.latitude;
      final longitude = marker.match.longitude;
      if (latitude == null || longitude == null) continue;

      final selected = marker.match.id == selectedMatchId;
      googleMarkers.add(
        gm.Marker(
          markerId: gm.MarkerId('match-${marker.match.id}'),
          position: gm.LatLng(latitude, longitude),
          zIndexInt: selected ? 2 : 1,
          icon: gm.BitmapDescriptor.defaultMarkerWithHue(
            selected
                ? gm.BitmapDescriptor.hueOrange
                : gm.BitmapDescriptor.hueRed,
          ),
          infoWindow: gm.InfoWindow(
            title: marker.match.sportName,
            snippet: marker.match.location,
          ),
          onTap: () => onMarkerTap(marker),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: gm.GoogleMap(
        key: ValueKey(
          'google-map-${center.latitude.toStringAsFixed(5)}-'
          '${center.longitude.toStringAsFixed(5)}-${markers.length}',
        ),
        initialCameraPosition: gm.CameraPosition(
          target: gm.LatLng(center.latitude, center.longitude),
          zoom: 13,
        ),
        markers: googleMarkers,
        mapType: gm.MapType.normal,
        minMaxZoomPreference: const gm.MinMaxZoomPreference(3, 18),
        mapToolbarEnabled: false,
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
        compassEnabled: true,
      ),
    );
  }
}

class _MatchMapPin extends StatelessWidget {
  const _MatchMapPin({
    required this.marker,
    required this.selected,
  });

  final MapMatchMarker marker;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final match = marker.match;

    return AnimatedScale(
      duration: const Duration(milliseconds: 160),
      scale: selected ? 1.05 : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            AppAssets.mapMatchMarkerSvg,
            width: selected ? 62 : 58,
            height: selected ? 70 : 66,
          ),
          Transform.translate(
            offset: const Offset(0, -3),
            child: Container(
              constraints: const BoxConstraints(minWidth: 118, maxWidth: 142),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : AppColors.controlBorder.withValues(alpha: 0.45),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.controlShadow,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    match.sportName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.homeMeta14.copyWith(
                      color: AppColors.heading,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    HomeDateTimeFormatter.compactDate(match.startsAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.homeMeta12,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentLocationMarker extends StatelessWidget {
  const _CurrentLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const ValueKey('map-current-location'),
      alignment: Alignment.center,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: AppColors.controlShadow,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
