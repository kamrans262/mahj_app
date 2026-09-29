import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/theme/app_colors.dart';
import 'package:mahj_app/app/theme/app_typography.dart';
import 'package:mahj_app/core/widgets/app_button.dart';

void main() {
  test('Map package preserves Match Created success design tokens', () {
    expect(AppColors.matchSuccess, const Color(0xFF319A3B));
    expect(AppColors.matchSuccessCardSurface, const Color(0xFFFFFFFF));
    expect(AppColors.matchSuccessBackdrop, const Color.fromRGBO(0, 0, 0, 0.60));
    expect(AppTypography.matchSuccessSecondaryButton.fontSize, 16);
  });

  testWidgets('shared AppButton still accepts success textStyle overrides', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton.secondary(
            label: 'Invite Players',
            onPressed: () {},
            textStyle: AppTypography.matchSuccessSecondaryButton,
          ),
        ),
      ),
    );

    expect(find.text('Invite Players'), findsOneWidget);
  });
}
