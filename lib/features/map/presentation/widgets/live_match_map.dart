import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

    return const LatLng(30.1575, 71.5249);
  }

  Set<Marker> get _googleMarkers {
    final result = <Marker>{};

    if (currentLocationLatitude != null && currentLocationLongitude != null) {
      result.add(
        Marker(
          markerId: const MarkerId('current-location'),
          position: LatLng(currentLocationLatitude!, currentLocationLongitude!),
          zIndexInt: 3,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Current Location'),
        ),
      );
    }

    for (final marker in markers) {
      final latitude = marker.match.latitude;
      final longitude = marker.match.longitude;
      if (latitude == null || longitude == null) continue;

      final selected = marker.match.id == selectedMatchId;
      result.add(
        Marker(
          markerId: MarkerId('match-${marker.match.id}'),
          position: LatLng(latitude, longitude),
          zIndexInt: selected ? 2 : 1,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            selected ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: marker.match.sportName,
            snippet: marker.match.location,
          ),
          onTap: () => onMarkerTap(marker),
        ),
      );
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final center = _initialCenter;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GoogleMap(
        key: ValueKey(
          'google-map-${center.latitude.toStringAsFixed(5)}-'
          '${center.longitude.toStringAsFixed(5)}-${markers.length}',
        ),
        initialCameraPosition: CameraPosition(target: center, zoom: 13),
        markers: _googleMarkers,
        mapType: MapType.normal,
        minMaxZoomPreference: const MinMaxZoomPreference(3, 18),
        mapToolbarEnabled: false,
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
        compassEnabled: true,
      ),
    );
  }
}
