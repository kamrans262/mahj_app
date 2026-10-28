import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;

import '../../../../app/theme/app_colors.dart';
import '../../../../core/maps/mahj_google_map_style.dart';
import '../../../../core/maps/mahj_google_marker.dart';
import '../../../home/presentation/home_date_time_formatter.dart';
import '../../domain/map_match_marker.dart';
import '../../domain/map_radius_camera.dart';

class LiveMatchMap extends StatefulWidget {
  const LiveMatchMap({
    required this.markers,
    required this.selectedMatchId,
    required this.onMarkerTap,
    required this.radiusMiles,
    super.key,
    this.centerLatitude,
    this.centerLongitude,
    this.currentLocationLatitude,
    this.currentLocationLongitude,
  });

  final List<MapMatchMarker> markers;
  final String? selectedMatchId;
  final ValueChanged<MapMatchMarker> onMarkerTap;
  final double radiusMiles;
  final double? centerLatitude;
  final double? centerLongitude;
  final double? currentLocationLatitude;
  final double? currentLocationLongitude;

  @override
  State<LiveMatchMap> createState() => _LiveMatchMapState();
}

class _LiveMatchMapState extends State<LiveMatchMap> {
  gm.GoogleMapController? _controller;
  Size _viewport = Size.zero;

  bool get _hasSearchOrigin =>
      widget.centerLatitude != null && widget.centerLongitude != null;

  gm.LatLng get _initialCenter {
    if (_hasSearchOrigin) {
      return gm.LatLng(widget.centerLatitude!, widget.centerLongitude!);
    }

    for (final marker in widget.markers) {
      final latitude = marker.match.latitude;
      final longitude = marker.match.longitude;
      if (latitude != null && longitude != null) {
        return gm.LatLng(latitude, longitude);
      }
    }

    // Preserve the prior fallback until a real location becomes available.
    return const gm.LatLng(30.1575, 71.5249);
  }

  double _radiusZoom(gm.LatLng center) => MapRadiusCamera.zoomForRadius(
    radiusMiles: widget.radiusMiles,
    latitude: center.latitude,
    viewportWidth: _viewport.width,
    viewportHeight: _viewport.height,
  );

  @override
  void didUpdateWidget(covariant LiveMatchMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    final searchChanged = widget.radiusMiles != oldWidget.radiusMiles ||
        widget.centerLatitude != oldWidget.centerLatitude ||
        widget.centerLongitude != oldWidget.centerLongitude;
    if (searchChanged) {
      _scheduleCameraUpdate();
    }
  }

  /// Never recreate the native Google Map when markers load or the radius
  /// changes. Animate its existing controller instead, preserving gestures.
  void _scheduleCameraUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_animateToSearchArea());
    });
  }

  Future<void> _animateToSearchArea() async {
    final controller = _controller;
    if (controller == null) return;

    try {
      if (_hasSearchOrigin) {
        final center = _initialCenter;
        await controller.animateCamera(
          gm.CameraUpdate.newCameraPosition(
            gm.CameraPosition(target: center, zoom: _radiusZoom(center)),
          ),
        );
        return;
      }

      // Without a verified search origin, do not draw a misleading radius
      // circle. Instead show the markers we actually have on the map.
      final points = widget.markers
          .where((marker) => marker.hasCoordinates)
          .map((marker) => gm.LatLng(
                marker.match.latitude!,
                marker.match.longitude!,
              ))
          .toList(growable: false);
      if (points.isEmpty) return;
      if (points.length == 1) {
        await controller.animateCamera(
          gm.CameraUpdate.newCameraPosition(
            gm.CameraPosition(target: points.first, zoom: 13),
          ),
        );
        return;
      }

      final south = points.map((point) => point.latitude).reduce(math.min);
      final north = points.map((point) => point.latitude).reduce(math.max);
      final west = points.map((point) => point.longitude).reduce(math.min);
      final east = points.map((point) => point.longitude).reduce(math.max);
      // A global dataset can cross the international date line. Let the user
      // pan in that rare case rather than fitting a misleading world view.
      if (east - west > 180) return;
      await controller.animateCamera(
        gm.CameraUpdate.newLatLngBounds(
          gm.LatLngBounds(
            southwest: gm.LatLng(south, west),
            northeast: gm.LatLng(north, east),
          ),
          48,
        ),
      );
    } catch (_) {
      // The platform map can be disposed during navigation/animation.
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      unawaited(controller.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewport = Size(constraints.maxWidth, constraints.maxHeight);
        return _buildGoogleMap();
      },
    );
  }

  Widget _buildGoogleMap() {
    final center = _initialCenter;

    MapMatchMarker? selectedMarker;
    for (final marker in widget.markers) {
      if (marker.match.id == widget.selectedMatchId) {
        selectedMarker = marker;
        break;
      }
    }

    final selectedIconFuture = selectedMarker == null
        ? MahjGoogleMarker.load(width: 50, height: 57)
        : MahjGoogleMarker.loadSelected(
            title: selectedMarker.match.sportName,
            subtitle: HomeDateTimeFormatter.compactDate(
              selectedMarker.match.startsAt,
            ),
          );

    return FutureBuilder<List<gm.BitmapDescriptor>>(
      future: Future.wait<gm.BitmapDescriptor>([
        MahjGoogleMarker.load(width: 50, height: 57),
        selectedIconFuture,
      ]),
      builder: (context, snapshot) {
        final matchIcon =
            snapshot.data?.first ??
            gm.BitmapDescriptor.defaultMarkerWithHue(
              MahjGoogleMarker.defaultGoogleMarkerHue,
            );
        final selectedIcon = snapshot.data?.last ?? matchIcon;
        final googleMarkers = <gm.Marker>{};

        if (widget.currentLocationLatitude != null &&
            widget.currentLocationLongitude != null) {
          googleMarkers.add(
            gm.Marker(
              markerId: const gm.MarkerId('current-location'),
              position: gm.LatLng(
                widget.currentLocationLatitude!,
                widget.currentLocationLongitude!,
              ),
              zIndexInt: 3,
              icon: gm.BitmapDescriptor.defaultMarkerWithHue(
                MahjGoogleMarker.defaultGoogleMarkerHue,
              ),
            ),
          );
        }

        for (final marker in widget.markers) {
          final latitude = marker.match.latitude;
          final longitude = marker.match.longitude;
          if (latitude == null || longitude == null) continue;

          final selected = marker.match.id == widget.selectedMatchId;
          googleMarkers.add(
            gm.Marker(
              markerId: gm.MarkerId('match-${marker.match.id}'),
              position: gm.LatLng(latitude, longitude),
              zIndexInt: selected ? 2 : 1,
              icon: selected ? selectedIcon : matchIcon,
              anchor: selected
                  ? const Offset(0.5, 57 / 113)
                  : const Offset(0.5, 1),
              consumeTapEvents: true,
              onTap: () => widget.onMarkerTap(marker),
            ),
          );
        }

        final searchCircles = _hasSearchOrigin
            ? <gm.Circle>{
                gm.Circle(
                  circleId: const gm.CircleId('mahj-search-radius'),
                  center: center,
                  radius: widget.radiusMiles * MapRadiusCamera.metersPerMile,
                  fillColor: AppColors.primary.withValues(alpha: 0.07),
                  strokeColor: AppColors.primary.withValues(alpha: 0.5),
                  strokeWidth: 2,
                ),
              }
            : <gm.Circle>{};

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: gm.GoogleMap(
            // A stable key keeps the native camera and controller intact when
            // fresh radius-filtered match markers arrive from the server.
            key: const ValueKey('mahj-live-google-map'),
            onMapCreated: (controller) {
              _controller = controller;
            },
            initialCameraPosition: gm.CameraPosition(
              target: center,
              zoom: _hasSearchOrigin ? _radiusZoom(center) : 13,
            ),
            markers: googleMarkers,
            circles: searchCircles,
            mapType: gm.MapType.normal,
            style: MahjGoogleMapStyle.json,
            minMaxZoomPreference: const gm.MinMaxZoomPreference(3, 18),
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            myLocationEnabled:
                widget.currentLocationLatitude != null &&
                widget.currentLocationLongitude != null,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
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
