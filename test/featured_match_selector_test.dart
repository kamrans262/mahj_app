import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/home/domain/featured_match_selector.dart';
import 'package:mahj_app/features/home/domain/home_match.dart';

void main() {
  final now = DateTime(2026, 10, 28, 12);

  HomeMatch match(
    String id, {
    String city = 'Austin',
    double? distance = 2,
    double? latitude,
    double? longitude,
    bool featured = false,
    int order = 0,
    MatchStatus status = MatchStatus.open,
    bool public = true,
    bool inviteOnly = false,
    bool joinable = true,
    bool joined = false,
    bool owned = false,
    int players = 2,
    int capacity = 4,
    Duration startsIn = const Duration(hours: 12),
  }) => HomeMatch(
    id: id,
    sportName: 'Mah Jongg',
    location: 'Community Center, $city, TX',
    startsAt: now.add(startsIn),
    currentPlayers: players,
    maxPlayers: capacity,
    status: status,
    isPublic: public,
    isInviteOnly: inviteOnly,
    isJoinable: joinable,
    isCurrentUserJoined: joined,
    isOwnedByCurrentUser: owned,
    distanceMiles: distance,
    latitude: latitude,
    longitude: longitude,
    isFeatured: featured,
    featuredOrder: order,
  );

  test('automatically selects local upcoming matches without admin flags', () {
    final picks = FeaturedMatchSelector.select([
      match('far-city', city: 'Dallas', distance: 80),
      match('local-2', distance: 4),
      match('local-1', distance: 1),
      match('local-3', distance: 3),
    ], now: now, hasCoordinates: true, radiusMiles: 6);

    expect(picks.map((m) => m.id), ['local-1', 'local-3', 'local-2']);
  });

  test('manual featured flag only overrides other matches inside the radius', () {
    final picks = FeaturedMatchSelector.select([
      match('near', distance: 0.2),
      match('outside', city: 'Dallas', distance: 45, featured: true),
      match('priority-2', distance: 3, featured: true, order: 5),
      match('priority-1', distance: 4, featured: true, order: 1),
    ], now: now, hasCoordinates: true, radiusMiles: 6);

    expect(picks.map((m) => m.id), ['priority-1', 'priority-2', 'near']);
  });

  test('filters past, closed, private, full and already joined matches', () {
    final picks = FeaturedMatchSelector.select([
      match('valid'),
      match('past', startsIn: const Duration(hours: -1)),
      match('cancelled', status: MatchStatus.cancelled),
      match('completed', status: MatchStatus.completed),
      match('full', players: 4),
      match('private', public: false),
      match('invite-only', inviteOnly: true),
      match('not-joinable', joinable: false),
      match('joined', joined: true),
    ], now: now, hasCoordinates: true, radiusMiles: 6);

    expect(picks.map((m) => m.id), ['valid']);
  });

  test('city fallback prevents unrelated cities when coordinates unavailable', () {
    final matches = [
      match('austin-1', city: 'Austin'),
      match('dallas', city: 'Dallas', featured: true),
      match('austin-2', city: 'Austin'),
    ];
    final picks = FeaturedMatchSelector.select(
      matches,
      now: now,
      hasCoordinates: false,
      radiusMiles: 6,
      city: 'Austin, TX',
    );
    expect(picks.map((m) => m.id), ['austin-1', 'austin-2']);
    expect(FeaturedMatchSelector.select(
      matches, now: now, hasCoordinates: false, radiusMiles: 6,
    ), isEmpty);
  });

  test('city names must match whole address components, not fragments', () {
    final picks = FeaturedMatchSelector.select([
      match('new-york', city: 'New York'),
      match('york', city: 'York'),
    ], now: now, hasCoordinates: false, radiusMiles: 6, city: 'York');
    expect(picks.map((m) => m.id), ['york']);
  });

  test('limits automatic carousel without mutating the discovery result', () {
    final matches = [
      for (var i = 0; i < 10; i++) match('$i', distance: i.toDouble()),
    ];
    final chosen = FeaturedMatchSelector.select(
      matches, now: now, hasCoordinates: true, radiusMiles: 10,
    );
    expect(chosen.length, 5);
    expect(matches.first.id, '0');
  });
  test('keeps eligible local features ahead of all global matches', () {
    final result = FeaturedMatchSelector.selectWithFallback(
      [
        match('local-open', distance: 2),
        match('local-featured', featured: true, distance: 5),
      ],
      [
        match('remote-sooner', city: 'Dallas', distance: 100,
            startsIn: const Duration(hours: 1)),
      ],
      now: now,
      hasCoordinates: true,
      radiusMiles: 6,
      city: 'Austin',
    );

    expect(result.isOtherCitiesFallback, false);
    expect(
      result.matches.map((match) => match.id),
      ['local-featured', 'local-open'],
    );
  });

  test('falls back to soonest upcoming open games from other cities', () {
    final result = FeaturedMatchSelector.selectWithFallback(
      const <HomeMatch>[],
      [
        match('far-later', city: 'Houston', distance: 70,
            startsIn: const Duration(days: 2)),
        match('far-sooner', city: 'Dallas', distance: 60,
            startsIn: const Duration(hours: 2)),
        match('far-featured-but-later', city: 'Waco', distance: 100,
            featured: true, startsIn: const Duration(hours: 5)),
        match('local-not-a-fallback', city: 'Austin', distance: 2),
        match('past', city: 'Dallas', distance: 60,
            startsIn: const Duration(hours: -1)),
        match('full', city: 'Houston', distance: 100, players: 4),
        match('private', city: 'Houston', distance: 100, public: false),
        match('invite-only', city: 'Houston', distance: 100, inviteOnly: true),
        match('not-joinable', city: 'Houston', distance: 100, joinable: false),
        match('already-joined', city: 'Houston', distance: 100, joined: true),
        match('owned', city: 'Houston', distance: 100, owned: true),
        match('cancelled', city: 'Houston', distance: 100,
            status: MatchStatus.cancelled),
        match('completed', city: 'Houston', distance: 100,
            status: MatchStatus.completed),
        match('confirmed', city: 'Houston', distance: 100,
            status: MatchStatus.confirmed),
      ],
      now: now,
      hasCoordinates: true,
      radiusMiles: 6,
      city: 'Austin',
    );

    expect(result.isOtherCitiesFallback, true);
    expect(
      result.matches.map((match) => match.id),
      ['far-sooner', 'far-featured-but-later', 'far-later'],
    );
  });

  test('cross-city fallback uses the city when GPS is unavailable', () {
    final result = FeaturedMatchSelector.selectWithFallback(
      const <HomeMatch>[],
      [
        match('same-city', city: 'Austin', distance: null),
        match('remote', city: 'Dallas', distance: null),
      ],
      now: now,
      hasCoordinates: false,
      radiusMiles: 6,
      city: 'Austin, TX',
    );
    expect(result.isOtherCitiesFallback, true);
    expect(result.matches.map((match) => match.id), ['remote']);
  });

  test('cross-city fallback computes distance for global records with GPS', () {
    final result = FeaturedMatchSelector.selectWithFallback(
      const <HomeMatch>[],
      [
        match('same-position', city: 'Austin', distance: null,
            latitude: 30.2672, longitude: -97.7431),
        match('outside', city: 'Dallas', distance: null,
            latitude: 32.7767, longitude: -96.7970),
      ],
      now: now,
      hasCoordinates: true,
      latitude: 30.2672,
      longitude: -97.7431,
      radiusMiles: 6,
      city: 'Austin',
    );
    expect(result.isOtherCitiesFallback, true);
    expect(result.matches.map((match) => match.id), ['outside']);
    expect(result.matches.single.distanceMiles, greaterThan(6));
  });

  test('does not invent matches or fall back when the limit is zero', () {
    final empty = FeaturedMatchSelector.selectWithFallback(
      const <HomeMatch>[],
      [match('unavailable', city: 'Dallas', status: MatchStatus.cancelled)],
      now: now, hasCoordinates: true, radiusMiles: 6,
    );
    expect(empty.matches, isEmpty);
    expect(empty.isOtherCitiesFallback, false);

    final disabled = FeaturedMatchSelector.selectWithFallback(
      const <HomeMatch>[],
      [match('remote', city: 'Dallas', distance: 80)],
      now: now, hasCoordinates: true, radiusMiles: 6, limit: 0,
    );
    expect(disabled.matches, isEmpty);
    expect(disabled.isOtherCitiesFallback, false);
  });

}
