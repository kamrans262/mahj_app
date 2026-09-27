import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/home/data/nearby_matches_preview_data.dart';
import 'package:mahj_app/features/home/domain/home_match.dart';

void main() {
  test('nearby preview data is builder-ready and contains all statuses', () {
    final matches = NearbyMatchesPreviewData.create();

    expect(matches, hasLength(12));
    expect(matches.map((match) => match.id).toSet(), hasLength(12));
    expect(matches.any((match) => match.status == MatchStatus.open), isTrue);
    expect(
      matches.any((match) => match.status == MatchStatus.confirmed),
      isTrue,
    );
    expect(
      matches.any((match) => match.status == MatchStatus.cancelled),
      isTrue,
    );
    expect(matches.any((match) => match.status == MatchStatus.full), isTrue);
  });
}
