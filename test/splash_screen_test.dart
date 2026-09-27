import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/theme/app_colors.dart';
import 'package:mahj_app/features/splash/presentation/splash_screen.dart';

void main() {
  test('primary color stays aligned with the design system', () {
    expect(AppColors.primary, const Color(0xFFEC5D01));
  });

  testWidgets('splash renders branded logo and primary loader', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen(navigateToLogin: false)),
    );

    expect(find.byKey(const ValueKey('splash-logo')), findsOneWidget);
    expect(find.byKey(const ValueKey('splash-loader')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
