import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart' as ll;

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
          width: 30,
          height: 30,
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
          width: 52,
          height: 52,
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
        ),
        children: [
          fm.TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.mahj_app',
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
