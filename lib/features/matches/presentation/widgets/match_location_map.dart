import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../core/maps/mahj_google_map_style.dart';
import '../../../../core/maps/mahj_google_marker.dart';
import '../../../home/domain/home_match.dart';

class MatchLocationMap extends StatelessWidget {
  const MatchLocationMap({required this.match, super.key});

  final HomeMatch match;

  @override
  Widget build(BuildContext context) {
    final latitude = match.latitude;
    final longitude = match.longitude;

    return Semantics(
      label: 'Match location map',
      child: AspectRatio(
        aspectRatio: 2.15,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: _buildMap(latitude, longitude),
        ),
      ),
    );
  }

  Widget _buildMap(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) {
      return const _MissingMatchLocation();
    }

    return _buildGoogleMap(latitude, longitude);
  }

  Widget _buildGoogleMap(double latitude, double longitude) {
    final position = gm.LatLng(latitude, longitude);

    return FutureBuilder<gm.BitmapDescriptor>(
      future: MahjGoogleMarker.load(width: 68, height: 78),
      builder: (context, snapshot) {
        final markerIcon =
            snapshot.data ??
            gm.BitmapDescriptor.defaultMarkerWithHue(
              gm.BitmapDescriptor.hueOrange,
            );

        return gm.GoogleMap(
          key: ValueKey('match-details-google-map-${match.id}'),
          initialCameraPosition: gm.CameraPosition(target: position, zoom: 15),
          markers: {
            gm.Marker(
              markerId: gm.MarkerId('match-details-${match.id}'),
              position: position,
              icon: markerIcon,
            ),
          },
          mapType: gm.MapType.normal,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          compassEnabled: true,
          onMapCreated: MahjGoogleMapStyle.apply,
        );
      },
    );
  }
}

class _MissingMatchLocation extends StatelessWidget {
  const _MissingMatchLocation();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.subtleSurface,
      child: Center(
        child: Text('Location map unavailable', textAlign: TextAlign.center),
      ),
    );
  }
}
