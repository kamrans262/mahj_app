import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/matches/domain/sport_option.dart';
import 'package:mahj_app/features/matches/presentation/create_match_screen.dart';

void main() {
  testWidgets('Other reveals custom sport name field', (tester) async {
    const sports = [
      SportOption(
        id: 1,
        name: 'American Football',
        slug: 'american-football',
        iconKey: 'football',
      ),
      SportOption(
        id: 2,
        name: 'Basketball',
        slug: 'basketball',
        iconKey: 'basketball',
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: CreateMatchScreen(sports: sports),
      ),
    );

    expect(find.text('Select Sport'), findsOneWidget);
    expect(find.text('Enter Sport Name'), findsNothing);

    await tester.tap(find.text('Select Sport'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Other').last);
    await tester.pumpAndSettle();

    expect(find.text('Enter Sport Name'), findsOneWidget);
  });
}
