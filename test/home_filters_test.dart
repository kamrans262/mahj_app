import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/home/domain/match_filters.dart';

void main() {
  test('default Home filters use supported values', () {
    final filters = MatchFilters.defaults();

    expect(filters.selectedLocation, MatchFilters.defaultLocation);
    expect(filters.radiusMiles, MatchFilters.defaultRadiusMiles);
    expect(filters.showOpenOnly, isTrue);
    expect(filters.sortOption, MatchSortOption.distance);
    expect(filters.dateFilter, MatchDateFilter.any);
    expect(filters.hasCoordinates, isFalse);
  });

  test('copyWith keeps location, radius, date and coordinates together', () {
    final original = MatchFilters.defaults();
    final updated = original.copyWith(
      selectedLocation: 'Central Park, New York, NY',
      radiusMiles: 8,
      dateFilter: MatchDateFilter.nextThreeDays,
      latitude: 40.785091,
      longitude: -73.968285,
    );

    expect(updated.selectedLocation, 'Central Park, New York, NY');
    expect(updated.radiusMiles, 8);
    expect(updated.dateFilter, MatchDateFilter.nextThreeDays);
    expect(updated.latitude, 40.785091);
    expect(updated.longitude, -73.968285);
    expect(updated.hasCoordinates, isTrue);
    expect(updated.showOpenOnly, original.showOpenOnly);
    expect(updated.sortOption, original.sortOption);
  });

  test('filters support value equality for shared persisted state', () {
    expect(MatchFilters.defaults(), MatchFilters.defaults());
  });
}
