import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/map/presentation/map_screen.dart';
import 'package:mahj_app/features/matches/presentation/my_matches_screen.dart';
import 'package:mahj_app/features/navigation/presentation/main_navigation_shell.dart';

void main() {
  Future<void> tapBottomNavigationLabel(
    WidgetTester tester,
    String label,
  ) async {
    final nav = find.byType(BottomNavigationBar);
    expect(nav, findsOneWidget);

    final target = find.descendant(of: nav, matching: find.text(label));
    expect(target, findsOneWidget);

    await tester.tap(target);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
  }

  testWidgets('Map and My Matches switch without render tree exceptions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: MainNavigationShell()));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tapBottomNavigationLabel(tester, 'Map');
    expect(find.byType(MapScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tapBottomNavigationLabel(tester, 'My Matches');
    expect(find.byType(MyMatchesScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tapBottomNavigationLabel(tester, 'Map');
    expect(find.byType(MapScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tapBottomNavigationLabel(tester, 'Home');
    expect(tester.takeException(), isNull);
  });
}
