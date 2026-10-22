import '../../home/data/location_repository.dart';
import '../../home/domain/discovery_location.dart';
import '../../home/domain/home_match.dart';
import '../../home/domain/match_filters.dart';
import 'match_repository.dart';

/// Resolves the distance for details opened from any match list, including
/// Mutual Games, whose API does not include a viewer-specific distance.
class MatchDistanceResolver {
  const MatchDistanceResolver({
    required this.repository,
    required this.locations,
  });

  final MatchRepository repository;
  final LocationRepository locations;

  Future<MatchDistanceResolution> resolve(
    HomeMatch match, {
    MatchFilters? selectedFilters,
  }) async {
    if (match.distanceMiles != null) {
      return MatchDistanceResolution(match: match);
    }

    var target = match;
    var estimatedVenue = false;

    if (!target.hasCoordinates) {
      final address = target.location.trim();
      // Older matches sometimes stored an address without map coordinates.
      // Do not geocode vague venue names: the first global Places result
      // could be in an entirely different city.
      if (!_isSpecificAddress(address)) {
        return MatchDistanceResolution(
          match: match,
          unavailableLabel: 'Match location not mapped',
        );
      }

      try {
        final found = await locations.search(address);
        final candidate = found
            .where((location) => _matchesAddress(address, location.label))
            .firstOrNull;
        if (candidate == null) {
          return MatchDistanceResolution(
            match: match,
            unavailableLabel: 'Match location not mapped',
          );
        }

        target = target.copyWith(
          latitude: candidate.latitude,
          longitude: candidate.longitude,
        );
        estimatedVenue = true;
      } catch (_) {
        return MatchDistanceResolution(
          match: match,
          unavailableLabel: 'Match location not mapped',
        );
      }
    }

    DiscoveryLocation? origin;
    var fromSelectedLocation = false;
    if (selectedFilters != null &&
        selectedFilters.hasCoordinates &&
        !selectedFilters.usesCurrentLocation) {
      origin = DiscoveryLocation(
        label: selectedFilters.selectedLocation,
        latitude: selectedFilters.latitude!,
        longitude: selectedFilters.longitude!,
      );
      fromSelectedLocation = true;
    } else {
      try {
        origin = await locations.currentLocationIfGranted();
      } catch (_) {
        // Try the previously resolved current location or request permission.
      }
      if (origin == null &&
          selectedFilters != null &&
          selectedFilters.hasCoordinates) {
        origin = DiscoveryLocation.current(
          latitude: selectedFilters.latitude!,
          longitude: selectedFilters.longitude!,
        );
      }
      if (origin == null) {
        try {
          origin = await locations.currentLocation();
        } catch (_) {
          // No distance should be invented without a viewer origin.
        }
      }
    }

    if (origin == null) {
      return MatchDistanceResolution(
        match: target,
        unavailableLabel: 'Enable location to see distance',
      );
    }

    return MatchDistanceResolution(
      match: repository.withDistanceFromOrigin(
        target,
        latitude: origin.latitude,
        longitude: origin.longitude,
      ),
      estimatedVenue: estimatedVenue,
      fromSelectedLocation: fromSelectedLocation,
    );
  }

  static bool _isSpecificAddress(String value) {
    return value.length >= 8 && value.contains(',');
  }

  static bool _matchesAddress(String address, String returnedLabel) {
    final segments = address
        .split(',')
        .map(_normalize)
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    if (segments.length < 2) return false;

    final candidate = _normalize(returnedLabel);
    if (segments.first.length < 4 || !candidate.contains(segments.first)) {
      return false;
    }

    // An address must also agree on its city/locality whenever supplied.
    for (final locality in segments.skip(1)) {
      if (locality.length >= 4 && !candidate.contains(locality)) {
        return false;
      }
    }
    return true;
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
}

class MatchDistanceResolution {
  const MatchDistanceResolution({
    required this.match,
    this.estimatedVenue = false,
    this.fromSelectedLocation = false,
    this.unavailableLabel = 'Distance unavailable',
  });

  final HomeMatch match;
  final bool estimatedVenue;
  final bool fromSelectedLocation;
  final String unavailableLabel;

  String get distanceLabel {
    final distance = match.distanceMiles;
    if (distance == null) return unavailableLabel;
    final prefix = estimatedVenue ? 'About ' : '';
    final suffix = fromSelectedLocation ? ' from selected location' : '';
    return '$prefix${distance.toStringAsFixed(1)} miles$suffix';
  }
}
