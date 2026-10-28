import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/home/domain/featured_match_selector.dart';
import 'package:mahj_app/features/home/domain/home_match.dart';

void main() {
  final now = DateTime(2026, 10, 29, 12);
  const austinLat = 30.2672;
  const austinLon = -97.7431;

  HomeMatch match(
    String id, {
    String city = 'Austin',
    double? latitude,
    double? longitude,
    double? staleDistance,
    bool featured = false,
    int order = 0,
    int startsAfterHours = 12,
    MatchStatus status = MatchStatus.open,
    bool public = true,
    bool inviteOnly = false,
    bool joinable = true,
    bool joined = false,
    bool owned = false,
    int players = 2,
    int capacity = 4,
  }) => HomeMatch(
    id: id,
    sportName: 'Mah Jongg',
    location: 'Community Center, $city, TX',
    startsAt: now.add(Duration(hours: startsAfterHours)),
    currentPlayers: players,
    maxPlayers: capacity,
    status: status,
    latitude: latitude,
    longitude: longitude,
    distanceMiles: staleDistance,
    isFeatured: featured,
    featuredOrder: order,
    isPublic: public,
    isInviteOnly: inviteOnly,
    isJoinable: joinable,
    isCurrentUserJoined: joined,
    isOwnedByCurrentUser: owned,
  );

  test('Home uses exactly 50 miles and only prioritizes local admin features', () {
    final selection = FeaturedMatchSelector.selectHomeBanner(
      [
        match('nonfeatured-10mi', latitude: 30.41, longitude: austinLon),
        match('featured-40mi', latitude: 30.85, longitude: austinLon,
            city: 'Buda', featured: true, order: 3),
        match('featured-city', city: 'Austin', latitude: 31.40,
            longitude: austinLon, featured: true, order: 1),
      ],
      [
        match('remote-featured', city: 'Dallas', latitude: 32.77,
            longitude: -96.79, featured: true, startsAfterHours: 1),
        match('nonfeatured-10mi', latitude: 30.41, longitude: austinLon),
      ],
      now: now,
      city: 'Austin',
      latitude: austinLat,
      longitude: austinLon,
    );

    expect(FeaturedMatchSelector.homeRadiusMiles, 50);
    expect(selection.isOtherCitiesFallback, isFalse);
    expect(selection.matches.map((m) => m.id), [
      'featured-city',
      'featured-40mi',
      'nonfeatured-10mi',
    ]);
    expect(selection.matches.last.distanceMiles, lessThan(50));
  });

  test('50-mile eligibility recalculates GPS distance, not stored filter distance', () {
    final selection = FeaturedMatchSelector.selectHomeBanner(
      const <HomeMatch>[],
      [
        match('inside', city: 'Buda', latitude: 30.90,
            longitude: austinLon, staleDistance: 999),
        match('outside', city: 'Dallas', latitude: 31.15,
            longitude: austinLon, staleDistance: 1, featured: true),
      ],
      now: now,
      city: 'Austin',
      latitude: austinLat,
      longitude: austinLon,
    );

    expect(selection.matches.map((m) => m.id), ['inside']);
    expect(selection.isOtherCitiesFallback, isFalse);
    expect(selection.matches.single.distanceMiles, lessThanOrEqualTo(50));
  });

  test('when no city/50-mile games exist, show future open matches anywhere', () {
    final selection = FeaturedMatchSelector.selectHomeBanner(
      const <HomeMatch>[],
      [
        match('remote-admin-later', city: 'Dallas', featured: true,
            startsAfterHours: 48),
        match('remote-next', city: 'Houston', startsAfterHours: 2),
        match('remote-third', city: 'Waco', startsAfterHours: 6),
        match('cancelled', city: 'Dallas', status: MatchStatus.cancelled),
        match('old', city: 'Dallas', startsAfterHours: -1),
        match('full', city: 'Dallas', players: 4),
        match('private', city: 'Dallas', public: false),
        match('invite-only', city: 'Dallas', inviteOnly: true),
        match('cannot-join', city: 'Dallas', joinable: false),
        match('already-joined', city: 'Dallas', joined: true),
        match('owned', city: 'Dallas', owned: true),
      ],
      now: now,
      city: 'Austin',
      latitude: austinLat,
      longitude: austinLon,
    );

    expect(selection.isOtherCitiesFallback, isTrue);
    expect(selection.matches.map((m) => m.id), [
      'remote-next',
      'remote-third',
      'remote-admin-later',
    ]);
    expect(selection.matches.length, 3); // Five is not compulsory.
  });

  test('without GPS, the saved user city still gets local-featured priority', () {
    final selection = FeaturedMatchSelector.selectHomeBanner(
      const <HomeMatch>[],
      [
        match('remote', city: 'Dallas', startsAfterHours: 1, featured: true),
        match('austin', city: 'Austin', startsAfterHours: 3),
        match('austin-featured', city: 'Austin', startsAfterHours: 5,
            featured: true),
      ],
      now: now,
      city: 'Austin, TX',
    );

    expect(selection.isOtherCitiesFallback, isFalse);
    expect(selection.matches.map((m) => m.id), [
      'austin-featured',
      'austin',
    ]);
  });

  test('without GPS or city, fallback is nonempty if any open match exists', () {
    final selection = FeaturedMatchSelector.selectHomeBanner(
      const <HomeMatch>[],
      [
        match('upcoming-later', city: 'Dallas', startsAfterHours: 4),
        match('upcoming-sooner', city: 'Houston', startsAfterHours: 1),
      ],
      now: now,
    );

    expect(selection.isOtherCitiesFallback, isTrue);
    expect(selection.matches.map((m) => m.id), [
      'upcoming-sooner',
      'upcoming-later',
    ]);
    expect(selection.matches.length, 2);
  });

  test('eligible global copy wins when an earlier radius result becomes joined', () {
    final selection = FeaturedMatchSelector.selectHomeBanner(
      [match('updated', city: 'Austin', latitude: austinLat,
          longitude: austinLon)],
      [match('updated', city: 'Austin', latitude: austinLat,
          longitude: austinLon, joined: true)],
      now: now,
      city: 'Austin',
      latitude: austinLat,
      longitude: austinLon,
    );
    expect(selection.matches, isEmpty);
    expect(selection.isOtherCitiesFallback, isFalse);
  });

  test('does not manufacture a banner when there are no eligible matches', () {
    final selection = FeaturedMatchSelector.selectHomeBanner(
      const <HomeMatch>[],
      [match('past', startsAfterHours: -3)],
      now: now,
      city: 'Austin',
    );
    expect(selection.matches, isEmpty);
    expect(selection.isOtherCitiesFallback, isFalse);
  });
}
