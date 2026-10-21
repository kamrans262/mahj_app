import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/home/domain/home_match.dart';
import 'package:mahj_app/features/home/presentation/home_date_time_formatter.dart';

void main() {
  test('UTC match time returned by Laravel displays in device local time', () {
    final utcSchedule = DateTime.utc(2030, 7, 16, 18, 30);
    final match = HomeMatch.fromJson({
      'id': 41,
      'sport_name': 'Mah Jongg',
      'location': 'Central Park',
      'starts_at': utcSchedule.toIso8601String(),
      'current_players': 1,
      'max_players': 4,
      'status': 'open',
    });

    expect(match.startsAt, utcSchedule.toLocal());
    expect(match.startsAt.isUtc, isFalse);
    expect(
      HomeDateTimeFormatter.time(match.startsAt),
      HomeDateTimeFormatter.time(utcSchedule.toLocal()),
    );
  });
}
