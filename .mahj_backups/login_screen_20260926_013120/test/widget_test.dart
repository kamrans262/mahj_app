import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/app.dart';

void main() {
  testWidgets('Mahj app starts on the splash screen', (tester) async {
    await tester.pumpWidget(const MahjApp());

    expect(find.byKey(const ValueKey('splash-logo')), findsOneWidget);
    expect(find.byKey(const ValueKey('splash-loader')), findsOneWidget);
  });
}
