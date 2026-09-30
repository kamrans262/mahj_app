import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart' as ll;

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../home/domain/home_match.dart';
import '../../../home/presentation/widgets/sport_icon.dart';

class MatchLocationMap extends StatelessWidget {
  const MatchLocationMap({
    required this.match,
    super.key,
  });

  static const String _mapProvider = String.fromEnvironment(
    'MAP_PROVIDER',
    defaultValue: 'osm',
  );

  final HomeMatch match;

  bool get _useGoogleMaps => _mapProvider.toLowerCase() == 'google';

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
              : _useGoogleMaps
              ? _buildGoogleMap(latitude, longitude)
              : _buildOpenStreetMap(latitude, longitude),
        ),
      ),
    );
  }

  Widget _buildOpenStreetMap(double latitude, double longitude) {
    final position = ll.LatLng(latitude, longitude);

    return fm.FlutterMap(
      options: fm.MapOptions(
        initialCenter: position,
        initialZoom: 15,
        minZoom: 3,
        maxZoom: 18,
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
              width: 54,
              height: 54,
              child: _SelectedMatchPin(match: match),
            ),
          ],
        ),
        const fm.RichAttributionWidget(
          attributions: [
            fm.TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }

  Widget _buildGoogleMap(double latitude, double longitude) {
    final position = gm.LatLng(latitude, longitude);

    return gm.GoogleMap(
      key: ValueKey('match-details-google-map-${match.id}'),
      initialCameraPosition: gm.CameraPosition(
        target: position,
        zoom: 15,
      ),
      markers: {
        gm.Marker(
          markerId: gm.MarkerId('match-details-${match.id}'),
          position: position,
          infoWindow: gm.InfoWindow(
            title: match.venueName?.trim().isNotEmpty == true
                ? match.venueName
                : match.sportName,
            snippet: match.location,
          ),
          icon: gm.BitmapDescriptor.defaultMarkerWithHue(
            gm.BitmapDescriptor.hueOrange,
          ),
        ),
      },
      mapType: gm.MapType.normal,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      compassEnabled: true,
    );
  }
}

class _SelectedMatchPin extends StatelessWidget {
  const _SelectedMatchPin({required this.match});

  final HomeMatch match;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 3),
        boxShadow: const [
          BoxShadow(
            color: AppColors.controlShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SportIcon(match: match, size: 28),
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
