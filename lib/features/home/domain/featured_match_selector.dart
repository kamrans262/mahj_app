import 'home_match.dart';

/// Chooses Home's featured carousel automatically from location-scoped
/// discovery results. Admin flags are optional local priorities, not a
/// requirement to maintain a featured item for every city.
///
/// Never promote a private, full, cancelled, past or non-joinable match.
/// Unknown location must not silently promote a match from another city.
abstract final class FeaturedMatchSelector {
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
      if (!match.startsAt.isAfter(now) ||
          match.status != MatchStatus.open ||
          match.isFull ||
          !match.isPublic ||
          match.isInviteOnly ||
          !match.isJoinable ||
          match.isOwnedByCurrentUser ||
          match.isCurrentUserJoined) {
        return false;
      }

      if (hasCoordinates) {
        final distance = match.distanceMiles;
        return distance != null &&
            distance.isFinite &&
            distance >= 0 &&
            distance <= radiusMiles;
      }

      final location = _normalize(match.location);
      // A whole city name avoids mistakenly matching a different city whose
      // name contains the searched text (e.g. York vs New York).
      return location == cityName ||
          location.startsWith('$cityName ') ||
          location.endsWith(' $cityName') ||
          location.contains(' $cityName ');
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

  static String _normalizedCity(String value) =>
      _normalize(value.split(',').first);

  static String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\\s+'), ' ');
}
