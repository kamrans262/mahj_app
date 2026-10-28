import 'dart:math' as math;

import 'home_match.dart';

/// Chooses Home's featured carousel automatically from location-scoped
/// discovery results. Admin flags are optional local priorities, not a
/// requirement to maintain a featured item for every city.
///
/// Never promote a private, full, cancelled, past or non-joinable match.
/// A broader search is used only if no eligible local match is available.
class FeaturedMatchSelection {
  const FeaturedMatchSelection({
    required this.matches,
    required this.isOtherCitiesFallback,
  });

  final List<HomeMatch> matches;
  final bool isOtherCitiesFallback;
}

abstract final class FeaturedMatchSelector {
  static const double _earthRadiusMiles = 3958.7613;

  /// Home's fixed radius, intentionally unrelated to Home/Map filter state.
  static const double homeRadiusMiles = 50;

  /// Selects Home banner matches using the viewer's actual location.
  ///
  /// Priority: eligible admin-featured matches in the user's city or within
  /// 50 miles, other eligible city/50-mile matches, then the next upcoming
  /// eligible matches anywhere. Only real available games can be displayed.
  ///
  /// [radiusMatches] comes from a dedicated 50-mile API request. [allMatches]
  /// comes from the existing global API request so the banner remains useful
  /// without location permission or when no local games exist.
  static FeaturedMatchSelection selectHomeBanner(
    Iterable<HomeMatch> radiusMatches,
    Iterable<HomeMatch> allMatches, {
    required DateTime now,
    String city = '',
    double? latitude,
    double? longitude,
    int limit = 5,
  }) {
    if (limit <= 0) {
      return const FeaturedMatchSelection(
        matches: <HomeMatch>[],
        isOtherCitiesFallback: false,
      );
    }

    final cityName = _normalizedCity(city);
    final hasOrigin = latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite &&
        latitude.abs() <= 90 &&
        longitude.abs() <= 180;

    // One copy of each match. The global API response is placed last so a
    // refreshed "joined", "full", or cancelled state supersedes stale
    // radius-search data when both responses contain the same ID.
    final byId = <String, HomeMatch>{};
    for (final match in radiusMatches) {
      byId[match.id] = match;
    }
    for (final match in allMatches) {
      byId[match.id] = match;
    }

    final eligible = byId.values.where((match) => _eligible(match, now)).map((
      match,
    ) {
      if (!hasOrigin || match.latitude == null || match.longitude == null) {
        return match;
      }

      // Global responses may have a distance computed for a different
      // discovery location. Always calculate from the viewer's GPS point.
      final distance = _distanceMiles(
        latitude!,
        longitude!,
        match.latitude!,
        match.longitude!,
      );
      return match.copyWith(distanceMiles: distance);
    }).toList(growable: false);

    final local = eligible.where((match) {
      final sameCity = cityName.isNotEmpty && _matchesCity(match, cityName);
      final within50Miles = hasOrigin &&
          match.latitude != null &&
          match.longitude != null &&
          match.distanceMiles != null &&
          match.distanceMiles!.isFinite &&
          match.distanceMiles! <= homeRadiusMiles;
      return sameCity || within50Miles;
    }).toList();

    if (local.isNotEmpty) {
      local.sort((a, b) {
        if (a.isFeatured != b.isFeatured) return a.isFeatured ? -1 : 1;
        if (a.isFeatured && b.isFeatured) {
          final order = a.featuredOrder.compareTo(b.featuredOrder);
          if (order != 0) return order;
        }

        final aDistance = a.distanceMiles;
        final bDistance = b.distanceMiles;
        if (hasOrigin &&
            aDistance != null &&
            bDistance != null &&
            aDistance.isFinite &&
            bDistance.isFinite) {
          final nearbyFirst = aDistance.compareTo(bDistance);
          if (nearbyFirst != 0) return nearbyFirst;
        }

        final schedule = a.startsAt.compareTo(b.startsAt);
        return schedule != 0 ? schedule : a.id.compareTo(b.id);
      });
      return FeaturedMatchSelection(
        matches: List<HomeMatch>.unmodifiable(local.take(limit)),
        isOtherCitiesFallback: false,
      );
    }

    // No admin priority outside the local area. Show the soonest future open
    // matches regardless of city, including when GPS/city is unavailable.
    eligible.sort((a, b) {
      final schedule = a.startsAt.compareTo(b.startsAt);
      return schedule != 0 ? schedule : a.id.compareTo(b.id);
    });

    return FeaturedMatchSelection(
      matches: List<HomeMatch>.unmodifiable(eligible.take(limit)),
      isOtherCitiesFallback: eligible.isNotEmpty,
    );
  }

  /// Keep local matches (including admin-prioritized ones) first. Only when
  /// there are none, show the next upcoming open matches outside the user's
  /// area, ignoring admin priority flags from unrelated cities.
  static FeaturedMatchSelection selectWithFallback(
    Iterable<HomeMatch> localMatches,
    Iterable<HomeMatch> allMatches, {
    required DateTime now,
    required bool hasCoordinates,
    required double radiusMiles,
    String city = '',
    double? latitude,
    double? longitude,
    int limit = 5,
  }) {
    final local = select(
      localMatches,
      now: now,
      hasCoordinates: hasCoordinates,
      radiusMiles: radiusMiles,
      city: city,
      limit: limit,
    );

    if (local.isNotEmpty || limit <= 0) {
      return FeaturedMatchSelection(
        matches: local,
        isOtherCitiesFallback: false,
      );
    }

    final cityName = _normalizedCity(city);
    final outsideArea = allMatches.where((match) => _eligible(match, now)).map(
      (match) {
        final distance = match.distanceMiles ??
            (hasCoordinates &&
                    latitude != null &&
                    longitude != null &&
                    match.latitude != null &&
                    match.longitude != null
                ? _distanceMiles(
                    latitude, longitude, match.latitude!, match.longitude!,
                  )
                : null);
        return distance == null
            ? match
            : match.copyWith(distanceMiles: distance);
      },
    ).where((match) {
      if (match.location.trim().isEmpty) return false;
      if (hasCoordinates &&
          match.distanceMiles != null &&
          match.distanceMiles! <= radiusMiles) {
        return false;
      }
      // A city-based check also protects unmapped legacy matches from
      // appearing under the "other cities" heading.
      return cityName.isEmpty || !_matchesCity(match, cityName);
    }).toList();

    // "Latest open matches" means the soonest upcoming games, not the most
    // recently created database rows. Manual flags are local-only priority.
    outsideArea.sort((a, b) {
      final time = a.startsAt.compareTo(b.startsAt);
      return time != 0 ? time : a.id.compareTo(b.id);
    });

    return FeaturedMatchSelection(
      matches: List<HomeMatch>.unmodifiable(outsideArea.take(limit)),
      isOtherCitiesFallback: outsideArea.isNotEmpty,
    );
  }

  static double _distanceMiles(
    double originLatitude,
    double originLongitude,
    double targetLatitude,
    double targetLongitude,
  ) {
    final latDelta = (targetLatitude - originLatitude) * math.pi / 180;
    final lonDelta = (targetLongitude - originLongitude) * math.pi / 180;
    final originRadians = originLatitude * math.pi / 180;
    final targetRadians = targetLatitude * math.pi / 180;
    final a = math.pow(math.sin(latDelta / 2), 2) +
        math.cos(originRadians) *
            math.cos(targetRadians) *
            math.pow(math.sin(lonDelta / 2), 2);
    final angle = 2 * math.atan2(
      math.sqrt(a.toDouble()),
      math.sqrt(math.max(0, 1 - a.toDouble())),
    );
    return _earthRadiusMiles * angle;
  }

  static List<HomeMatch> select(
    Iterable<HomeMatch> matches, {
    required DateTime now,
    required bool hasCoordinates,
    required double radiusMiles,
    String city = '',
    int limit = 5,
  }) {
    if (limit <= 0) return const <HomeMatch>[];

    final cityName = _normalizedCity(city);
    if (!hasCoordinates && cityName.isEmpty) {
      return const <HomeMatch>[];
    }

    final candidates = matches.where((match) {
      if (!_eligible(match, now)) {
        return false;
      }

      if (hasCoordinates) {
        final distance = match.distanceMiles;
        return distance != null &&
            distance.isFinite &&
            distance >= 0 &&
            distance <= radiusMiles;
      }

      // Compare comma-delimited city/address components, not arbitrary
      // substrings: "York" must never match "New York".
      return _matchesCity(match, cityName);
    }).toList();

    candidates.sort((a, b) {
      // Preserve the admin override *within* the relevant city/radius only.
      if (a.isFeatured != b.isFeatured) return a.isFeatured ? -1 : 1;
      if (a.isFeatured && b.isFeatured) {
        final order = a.featuredOrder.compareTo(b.featuredOrder);
        if (order != 0) return order;
      }
      if (hasCoordinates) {
        final proximity =
            a.distanceMiles!.compareTo(b.distanceMiles!);
        if (proximity != 0) return proximity;
      }
      final time = a.startsAt.compareTo(b.startsAt);
      return time != 0 ? time : a.id.compareTo(b.id);
    });

    return List<HomeMatch>.unmodifiable(candidates.take(limit));
  }

  static bool _eligible(HomeMatch match, DateTime now) =>
      match.startsAt.isAfter(now) &&
      match.status == MatchStatus.open &&
      !match.isFull &&
      match.isPublic &&
      !match.isInviteOnly &&
      match.isJoinable &&
      !match.isOwnedByCurrentUser &&
      !match.isCurrentUserJoined;

  static bool _matchesCity(HomeMatch match, String cityName) {
    final parts = match.location.split(',').map(_normalize);
    return parts.any((part) =>
        part == cityName || part.startsWith('$cityName '));
  }

  static String _normalizedCity(String value) =>
      _normalize(value.split(',').first);

  static String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r' +'), ' ');
}
