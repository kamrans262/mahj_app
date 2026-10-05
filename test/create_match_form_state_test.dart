import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/matches/domain/create_match_form_state.dart';
import 'package:mahj_app/features/matches/domain/sport_option.dart';

void main() {
  const mahJongg = SportOption(
    id: 1,
    name: 'Mah Jongg',
    slug: 'mah-jongg',
    iconKey: 'generic',
  );

  test('Create Match required fields exclude optional venue', () {
    const state = CreateMatchFormState(
      selectedSport: mahJongg,
      locationAddress: '1001, New York, NY',
      selectedDate: null,
      selectedTimeMinutes: null,
    );

    expect(state.hasRequiredFields, isFalse);
  });

  test('Create Match request uses Mah Jongg with date and time', () {
    final state = CreateMatchFormState(
      selectedSport: mahJongg,
      locationAddress: '1001, New York, NY',
      venueName: 'Central Park Courts',
      selectedDate: DateTime(2026, 9, 28),
      selectedTimeMinutes: 18 * 60 + 30,
      isPublicMatch: true,
      isInviteOnly: false,
    );

    final request = state.toRequest();

    expect(request, isNotNull);
    expect(request!.sportId, 1);
    expect(request.sportName, 'Mah Jongg');
    expect(request.sportSlug, 'mah-jongg');
    expect(request.sportIconKey, 'generic');
    expect(request.customSportName, isNull);
    expect(request.venueName, 'Central Park Courts');
    expect(request.startsAt, DateTime(2026, 9, 28, 18, 30));
    expect(request.isPublicMatch, isTrue);
    expect(request.isInviteOnly, isFalse);
  });

  test('blank optional venue maps to null in backend request', () {
    final state = CreateMatchFormState(
      selectedSport: mahJongg,
      locationAddress: 'Current Location',
      venueName: '   ',
      selectedDate: DateTime(2026, 9, 28),
      selectedTimeMinutes: 9 * 60,
    );

    expect(state.toRequest()!.venueName, isNull);
  });
}
