import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/home/domain/match_filters.dart';

void main() {
  test('default Home filters use supported values', () {
    final filters = MatchFilters.defaults();

    expect(filters.selectedLocation, MatchFilters.defaultLocation);
    expect(filters.radiusMiles, MatchFilters.defaultRadiusMiles);
    expect(filters.showOpenOnly, isTrue);
    expect(filters.sortOption, MatchSortOption.distance);
  });

  test('copyWith changes only requested filter values', () {
    final original = MatchFilters.defaults();
    final updated = original.copyWith(
      selectedLocation: 'Central Park Courts',
      radiusMiles: 8,
    );

    expect(updated.selectedLocation, 'Central Park Courts');
    expect(updated.radiusMiles, 8);
    expect(updated.showOpenOnly, original.showOpenOnly);
    expect(updated.sortOption, original.sortOption);
  });

  test('filters support value equality for persisted state', () {
    expect(MatchFilters.defaults(), MatchFilters.defaults());
  });
}
