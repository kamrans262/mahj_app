import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/map/domain/map_radius_camera.dart';

void main() {
  test('increasing the selected radius zooms out around the same location', () {
    const latitude = 40.7128;
    const width = 390.0;
    const height = 475.0;
    final one = MapRadiusCamera.zoomForRadius(
      radiusMiles: 1,
      latitude: latitude,
      viewportWidth: width,
      viewportHeight: height,
    );
    final ten = MapRadiusCamera.zoomForRadius(
      radiusMiles: 10,
      latitude: latitude,
      viewportWidth: width,
      viewportHeight: height,
    );
    final fifty = MapRadiusCamera.zoomForRadius(
      radiusMiles: 50,
      latitude: latitude,
      viewportWidth: width,
      viewportHeight: height,
    );
    expect(one, greaterThan(ten));
    expect(ten, greaterThan(fifty));
    expect(one - ten, closeTo(3.321928, 0.01));
    expect(ten - fifty, closeTo(2.321928, 0.01));
  });

  test('viewport width and height affect the fit without losing radius', () {
    final narrow = MapRadiusCamera.zoomForRadius(
      radiusMiles: 10,
      latitude: 30,
      viewportWidth: 300,
      viewportHeight: 500,
    );
    final wide = MapRadiusCamera.zoomForRadius(
      radiusMiles: 10,
      latitude: 30,
      viewportWidth: 600,
      viewportHeight: 700,
    );
    expect(narrow, lessThan(wide));
  });

  test('zoom stays finite and within Google Maps configured bounds', () {
    for (final latitude in [-85.0, -60.0, 0.0, 60.0, 85.0]) {
      for (final radius in [1.0, 5.0, 10.0, 50.0]) {
        final zoom = MapRadiusCamera.zoomForRadius(
          radiusMiles: radius,
          latitude: latitude,
          viewportWidth: 320,
          viewportHeight: 390,
        );
        expect(zoom.isFinite, isTrue);
        expect(zoom, inInclusiveRange(3.0, 18.0));
      }
    }
  });

  test('invalid viewport falls back to a usable initial camera zoom', () {
    expect(
      MapRadiusCamera.zoomForRadius(
        radiusMiles: 10,
        latitude: 30,
        viewportWidth: 0,
        viewportHeight: 0,
      ),
      13,
    );
  });
}
