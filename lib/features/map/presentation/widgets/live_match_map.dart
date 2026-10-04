import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;

import '../../../../core/maps/mahj_google_marker.dart';
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

  @override
  Widget build(BuildContext context) {
    return _buildGoogleMap();
  }

  Widget _buildGoogleMap() {
    final center = _initialCenter;

    return FutureBuilder<gm.BitmapDescriptor>(
      future: MahjGoogleMarker.load(width: 50, height: 57),
      builder: (context, snapshot) {
        final matchIcon =
            snapshot.data ??
            gm.BitmapDescriptor.defaultMarkerWithHue(
              gm.BitmapDescriptor.hueOrange,
            );
        final googleMarkers = <gm.Marker>{};

        if (currentLocationLatitude != null &&
            currentLocationLongitude != null) {
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
              icon: matchIcon,
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
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
          ),
        );
      },
    );
  }
}
