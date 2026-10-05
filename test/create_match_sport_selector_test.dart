import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/matches/domain/sport_option.dart';
import 'package:mahj_app/features/matches/presentation/create_match_screen.dart';

void main() {
  testWidgets('Mah Jongg is preselected with no sport dropdown', (tester) async {
    const sports = [
      SportOption(
        id: 1,
        name: 'Mah Jongg',
        slug: 'mah-jongg',
        iconKey: 'generic',
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(home: CreateMatchScreen(sports: sports)),
    );

    expect(find.text('Mah Jongg'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.text('Other'), findsNothing);
    expect(find.text('Enter Sport Name'), findsNothing);
  });
}
