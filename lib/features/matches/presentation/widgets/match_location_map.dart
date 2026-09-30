import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart' as ll;

import '../../../../app/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../home/domain/home_match.dart';

class MatchLocationMap extends StatelessWidget {
  const MatchLocationMap({required this.match, super.key});

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
          child: _buildMap(latitude, longitude),
        ),
      ),
    );
  }

  Widget _buildMap(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) {
      return const _MissingMatchLocation();
    }

    if (_useGoogleMaps) {
      return _buildGoogleMap(latitude, longitude);
    }

    return _buildOpenStreetMap(latitude, longitude);
  }

  Widget _buildOpenStreetMap(double latitude, double longitude) {
    final position = ll.LatLng(latitude, longitude);

    return fm.FlutterMap(
      options: fm.MapOptions(
        initialCenter: position,
        initialZoom: 15,
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
        fm.MarkerLayer(
          markers: [
            fm.Marker(
              point: position,
              width: 74,
              height: 86,
              alignment: const Alignment(0, -0.20),
              child: Image.asset(
                AppAssets.mapMatchMarkerPng,
                key: const ValueKey('match-details-map-marker'),
                width: 68,
                height: 78,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
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
            0.72,
            0,
            0,
            0,
            64,
            0,
            0.72,
            0,
            0,
            62,
            0,
            0,
            0.72,
            0,
            58,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: tileWidget,
        ),
        const ColoredBox(color: Color(0x0DEC5D01)),
      ],
    );
  }

  Widget _buildGoogleMap(double latitude, double longitude) {
    final position = gm.LatLng(latitude, longitude);

    return gm.GoogleMap(
      key: ValueKey('match-details-google-map-${match.id}'),
      initialCameraPosition: gm.CameraPosition(target: position, zoom: 15),
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
