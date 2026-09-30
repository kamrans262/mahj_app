import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../home/presentation/widgets/sport_icon.dart';
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

  final List<MapMatchMarker> markers;
  final String? selectedMatchId;
  final ValueChanged<MapMatchMarker> onMarkerTap;
  final double? centerLatitude;
  final double? centerLongitude;
  final double? currentLocationLatitude;
  final double? currentLocationLongitude;

  LatLng get _initialCenter {
    if (centerLatitude != null && centerLongitude != null) {
      return LatLng(centerLatitude!, centerLongitude!);
    }

    for (final marker in markers) {
      final latitude = marker.match.latitude;
      final longitude = marker.match.longitude;
      if (latitude != null && longitude != null) {
        return LatLng(latitude, longitude);
      }
    }

    return const LatLng(40.785091, -73.968285);
  }

  @override
  Widget build(BuildContext context) {
    final mapMarkers = <Marker>[];

    if (currentLocationLatitude != null && currentLocationLongitude != null) {
      mapMarkers.add(
        Marker(
          point: LatLng(currentLocationLatitude!, currentLocationLongitude!),
          width: 28,
          height: 28,
          child: const _CurrentLocationMarker(),
        ),
      );
    }

    for (final marker in markers) {
      final latitude = marker.match.latitude;
      final longitude = marker.match.longitude;
      if (latitude == null || longitude == null) continue;

      mapMarkers.add(
        Marker(
          point: LatLng(latitude, longitude),
          width: 50,
          height: 50,
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
      child: FlutterMap(
        options: MapOptions(
          initialCenter: _initialCenter,
          initialZoom: 13,
          minZoom: 3,
          maxZoom: 18,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.mahj_app',
          ),
          MarkerLayer(markers: mapMarkers),
          const RichAttributionWidget(
            attributions: [TextSourceAttribution('OpenStreetMap contributors')],
          ),
        ],
      ),
    );
  }
}

class _MatchMapPin extends StatelessWidget {
  const _MatchMapPin({required this.marker, required this.selected});

  final MapMatchMarker marker;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.controlBorder,
          width: selected ? 3 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.controlShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SportIcon(match: marker.match, size: 28),
    );
  }
}

class _CurrentLocationMarker extends StatelessWidget {
  const _CurrentLocationMarker();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('map-current-location'),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.controlShadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.my_location, size: 16, color: AppColors.primary),
      ),
    );
  }
}
