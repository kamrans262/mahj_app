import 'package:geolocator/geolocator.dart';

import '../../../core/network/api_client.dart';
import '../domain/discovery_location.dart';

class LocationAccessException implements Exception {
  const LocationAccessException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocationRepository {
  const LocationRepository({required ApiClient apiClient}) : this._(apiClient);

  const LocationRepository._(this._apiClient);

  final ApiClient _apiClient;

  Future<List<DiscoveryLocation>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];

    final path = Uri(
      path: '/locations/search',
      queryParameters: {'q': trimmed},
    ).toString();
    final payload = await _apiClient.get(path);
    final raw = payload['data'];
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map(
          (item) => DiscoveryLocation.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .where((location) => location.label.isNotEmpty)
        .toList(growable: false);
  }

  Future<DiscoveryLocation> currentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationAccessException(
        'Turn on location services to use your current location.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationAccessException(
        'Location permission is needed to find nearby matches.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationAccessException(
        'Location permission is disabled. Enable it in your device settings.',
      );
    }

    return _readCurrentLocation(
      const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
  }

  Future<DiscoveryLocation?> currentLocationIfGranted() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return null;
    }

    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return null;
    }

    try {
      return await _readCurrentLocation(
        const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 3),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<DiscoveryLocation> _readCurrentLocation(
    LocationSettings settings,
  ) async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: settings,
    );

    return DiscoveryLocation.current(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
