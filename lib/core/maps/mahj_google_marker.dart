import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;

import '../../app/app_assets.dart';

abstract final class MahjGoogleMarker {
  static final Map<String, Future<gm.BitmapDescriptor>> _cache =
      <String, Future<gm.BitmapDescriptor>>{};

  static Future<gm.BitmapDescriptor> load({
    double width = 54,
    double height = 61,
  }) {
    final key = '${width.toStringAsFixed(1)}x${height.toStringAsFixed(1)}';
    return _cache.putIfAbsent(
      key,
      () => gm.BitmapDescriptor.asset(
        ImageConfiguration(size: Size(width, height)),
        AppAssets.mapMatchMarkerPng,
        width: width,
        height: height,
      ),
    );
  }
}
