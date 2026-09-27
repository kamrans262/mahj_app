import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/home/domain/match_filters.dart';

void main() {
  test('Home filters defaults stay within supported radius', () {
    final filters = MatchFilters.defaults();

    expect(
      filters.radiusMiles,
      inInclusiveRange(
        MatchFilters.minRadiusMiles,
        MatchFilters.maxRadiusMiles,
      ),
    );
    expect(filters.showOpenOnly, isTrue);
    expect(filters.sortOption, MatchSortOption.distance);
  });

  test('Home filters copyWith preserves unchanged values', () {
    final original = MatchFilters.defaults();
    final updated = original.copyWith(radiusMiles: 8);

    expect(updated.radiusMiles, 8);
    expect(updated.selectedLocation, original.selectedLocation);
    expect(updated.showOpenOnly, original.showOpenOnly);
    expect(updated.sortOption, original.sortOption);
  });
}
