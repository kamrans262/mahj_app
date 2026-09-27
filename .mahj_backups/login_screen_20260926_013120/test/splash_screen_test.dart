import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/app.dart';
import 'package:mahj_app/app/theme/app_colors.dart';

void main() {
  test('primary color stays aligned with the design system', () {
    expect(AppColors.primary, const Color(0xFFEC5D01));
  });

  testWidgets('splash screen renders the logo and loading animation', (
    tester,
  ) async {
    await tester.pumpWidget(const MahjApp());

    expect(find.byKey(const ValueKey('splash-logo')), findsOneWidget);
    expect(find.byKey(const ValueKey('splash-loader')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
