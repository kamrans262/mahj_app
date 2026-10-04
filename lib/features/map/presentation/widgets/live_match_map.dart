import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart' as ll;

import '../../../../app/app_assets.dart';
import '../../../../app/map/app_map_config.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/maps/mahj_google_marker.dart';
import '../../../../core/widgets/app_surface_container.dart';
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
    return AppMapConfig.useGoogleMaps
        ? _buildGoogleMap()
        : _buildOpenStreetMap();
  }

  Widget _buildOpenStreetMap() {
    final center = _initialCenter;
    final mapMarkers = <fm.Marker>[];

    if (currentLocationLatitude != null && currentLocationLongitude != null) {
      mapMarkers.add(
        fm.Marker(
          point: ll.LatLng(currentLocationLatitude!, currentLocationLongitude!),
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
          width: 126,
          height: 136,
          alignment: const Alignment(0, -0.10),
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
              icon: matchIcon,
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
      },
    );
  }
}

class _MatchMapPin extends StatelessWidget {
  const _MatchMapPin({required this.marker, required this.selected});

  final MapMatchMarker marker;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final match = marker.match;

    return Semantics(
      button: true,
      selected: selected,
      label: '${match.sportName} map marker',
      value: HomeDateTimeFormatter.compactDate(match.startsAt),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: selected ? 1.06 : 1,
        child: SizedBox(
          width: 126,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AppAssets.mapMatchMarkerPng,
                width: selected ? 54 : 50,
                height: selected ? 61 : 57,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(height: 4),
              AppSurfaceContainer(
                minHeight: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      match.sportName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTypography.homeMeta12.copyWith(
                        color: AppColors.heading,
                      ),
                    ),
                    const SizedBox(height: 5),
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
            ],
          ),
        ),
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
