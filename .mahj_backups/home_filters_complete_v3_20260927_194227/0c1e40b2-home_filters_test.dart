import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/home/domain/match_filters.dart';

void main() {
  test('default Home filters match supported values', () {
    final filters = MatchFilters.defaults();

    expect(filters.selectedLocation, MatchFilters.defaultLocation);
    expect(filters.radiusMiles, MatchFilters.defaultRadiusMiles);
    expect(filters.showOpenOnly, isTrue);
    expect(filters.sortOption, MatchSortOption.distance);
  });

  test('copyWith preserves unmodified filter fields', () {
    final original = MatchFilters.defaults();
    final changed = original.copyWith(radiusMiles: 8);

    expect(changed.radiusMiles, 8);
    expect(changed.selectedLocation, original.selectedLocation);
    expect(changed.showOpenOnly, original.showOpenOnly);
    expect(changed.sortOption, original.sortOption);
  });

  test('filter value equality works for persisted sheet state', () {
    expect(MatchFilters.defaults(), MatchFilters.defaults());
  });
}
