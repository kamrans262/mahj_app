import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../home/domain/home_match.dart';

class MatchLocationMap extends StatelessWidget {
  const MatchLocationMap({
    required this.match,
    super.key,
  });

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
          child: latitude == null || longitude == null
              ? const _MissingMatchLocation()
              : GoogleMap(
                  key: ValueKey('match-details-google-map-${match.id}'),
                  initialCameraPosition: CameraPosition(
                    target: LatLng(latitude, longitude),
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId('match-details-${match.id}'),
                      position: LatLng(latitude, longitude),
                      infoWindow: InfoWindow(
                        title: match.venueName?.trim().isNotEmpty == true
                            ? match.venueName
                            : match.sportName,
                        snippet: match.location,
                      ),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueOrange,
                      ),
                    ),
                  },
                  mapType: MapType.normal,
                  mapToolbarEnabled: false,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  compassEnabled: true,
                ),
        ),
      ),
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
        child: Text(
          'Location map unavailable',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
