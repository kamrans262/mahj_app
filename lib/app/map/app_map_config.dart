abstract final class AppMapConfig {
  // Temporary app-wide map provider. Keep the OpenStreetMap implementations
  // in place so we can switch back later without rebuilding the map surfaces.
  static const bool useGoogleMaps = true;
}
