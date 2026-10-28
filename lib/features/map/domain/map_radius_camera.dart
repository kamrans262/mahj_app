import 'dart:math' as math;

/// Calculates the Google Maps zoom needed to keep an entire search radius
/// visible, including padding for Mahj's custom match markers.
///
/// Uses Web Mercator ground resolution at the search origin. The viewport is
/// measured in logical pixels, as used by the Google Maps camera zoom scale.
abstract final class MapRadiusCamera {
  static const double metersPerMile = 1609.344;
  static const double _equatorMetersPerPixel = 156543.03392804097;
  static const double _viewportFraction = 0.64;

  static double zoomForRadius({
    required double radiusMiles,
    required double latitude,
    required double viewportWidth,
    required double viewportHeight,
  }) {
    if (!radiusMiles.isFinite ||
        !latitude.isFinite ||
        !viewportWidth.isFinite ||
        !viewportHeight.isFinite ||
        viewportWidth <= 0 ||
        viewportHeight <= 0) {
      return 13;
    }

    final safeLatitude = latitude.clamp(-85.0, 85.0).toDouble();
    final radiusMeters = radiusMiles.clamp(1.0, 50.0) * metersPerMile;
    final usablePixels = math.min(viewportWidth, viewportHeight) *
        _viewportFraction;
    final groundMetersPerPixel = (radiusMeters * 2) / usablePixels;
    final equatorScale = _equatorMetersPerPixel *
        math.cos(safeLatitude * math.pi / 180);

    final zoom = math.log(equatorScale / groundMetersPerPixel) / math.ln2;
    return zoom.clamp(3.0, 18.0).toDouble();
  }
}
