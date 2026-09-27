import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/app.dart';

void main() {
  testWidgets('Mahj app starts on branded splash then opens login', (
    tester,
  ) async {
    await tester.pumpWidget(const MahjApp());

    expect(find.byKey(const ValueKey('splash-logo')), findsOneWidget);
    expect(find.byKey(const ValueKey('splash-loader')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('login-heading')), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
