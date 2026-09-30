import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/matches/domain/create_match_form_state.dart';

void main() {
  test('Create Match required fields exclude optional venue', () {
    const state = CreateMatchFormState(
      matchName: 'Basketball',
      locationAddress: '1001, New York, NY',
      selectedDate: null,
      selectedTimeMinutes: null,
    );

    expect(state.hasRequiredFields, isFalse);
  });

  test('Create Match request combines structured date and time', () {
    final state = CreateMatchFormState(
      matchName: 'Basketball',
      locationAddress: '1001, New York, NY',
      venueName: 'Central Park Courts',
      selectedDate: DateTime(2026, 9, 28),
      selectedTimeMinutes: 18 * 60 + 30,
      isPublicMatch: true,
      isInviteOnly: false,
    );

    final request = state.toRequest();

    expect(request, isNotNull);
    expect(request!.matchName, 'Basketball');
    expect(request.venueName, 'Central Park Courts');
    expect(request.startsAt, DateTime(2026, 9, 28, 18, 30));
    expect(request.isPublicMatch, isTrue);
    expect(request.isInviteOnly, isFalse);
  });

  test('blank match name does not create backend request', () {
    final state = CreateMatchFormState(
      matchName: '   ',
      locationAddress: 'Current Location',
      selectedDate: DateTime(2026, 9, 28),
      selectedTimeMinutes: 9 * 60,
    );

    expect(state.hasRequiredFields, isFalse);
    expect(state.toRequest(), isNull);
  });

  test('blank optional venue maps to null in backend request', () {
    final state = CreateMatchFormState(
      matchName: 'Football',
      locationAddress: 'Current Location',
      venueName: '   ',
      selectedDate: DateTime(2026, 9, 28),
      selectedTimeMinutes: 9 * 60,
    );

    expect(state.toRequest()!.venueName, isNull);
  });
}
