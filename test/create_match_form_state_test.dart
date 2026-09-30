import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/matches/domain/create_match_form_state.dart';
import 'package:mahj_app/features/matches/domain/sport_option.dart';

void main() {
  const basketball = SportOption(
    id: 2,
    name: 'Basketball',
    slug: 'basketball',
    iconKey: 'basketball',
  );

  test('Create Match required fields exclude optional venue', () {
    const state = CreateMatchFormState(
      selectedSport: basketball,
      locationAddress: '1001, New York, NY',
      selectedDate: null,
      selectedTimeMinutes: null,
    );

    expect(state.hasRequiredFields, isFalse);
  });

  test('Create Match request combines sport, date and time', () {
    final state = CreateMatchFormState(
      selectedSport: basketball,
      locationAddress: '1001, New York, NY',
      venueName: 'Central Park Courts',
      selectedDate: DateTime(2026, 9, 28),
      selectedTimeMinutes: 18 * 60 + 30,
      isPublicMatch: true,
      isInviteOnly: false,
    );

    final request = state.toRequest();

    expect(request, isNotNull);
    expect(request!.sportId, 2);
    expect(request.sportName, 'Basketball');
    expect(request.sportSlug, 'basketball');
    expect(request.sportIconKey, 'basketball');
    expect(request.customSportName, isNull);
    expect(request.venueName, 'Central Park Courts');
    expect(request.startsAt, DateTime(2026, 9, 28, 18, 30));
    expect(request.isPublicMatch, isTrue);
    expect(request.isInviteOnly, isFalse);
  });

  test('Other requires a custom sport name', () {
    final missingName = CreateMatchFormState(
      selectedSport: SportOption.other,
      customSportName: '   ',
      locationAddress: 'Current Location',
      selectedDate: DateTime(2026, 9, 28),
      selectedTimeMinutes: 9 * 60,
    );

    expect(missingName.hasRequiredFields, isFalse);
    expect(missingName.toRequest(), isNull);

    final valid = missingName.copyWith(customSportName: 'Ultimate Frisbee');
    final request = valid.toRequest();

    expect(request, isNotNull);
    expect(request!.sportId, isNull);
    expect(request.customSportName, 'Ultimate Frisbee');
    expect(request.sportName, 'Ultimate Frisbee');
    expect(request.sportIconKey, 'generic');
  });

  test('blank optional venue maps to null in backend request', () {
    final state = CreateMatchFormState(
      selectedSport: basketball,
      locationAddress: 'Current Location',
      venueName: '   ',
      selectedDate: DateTime(2026, 9, 28),
      selectedTimeMinutes: 9 * 60,
    );

    expect(state.toRequest()!.venueName, isNull);
  });
}
