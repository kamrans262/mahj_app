import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/theme/app_colors.dart';

void main() {
  test('shared reusable surfaces are solid #FFFDFC', () {
    const expected = Color(0xFFFFFDFC);

    expect(AppColors.nearbyMatchCardSurface, expected);
    expect(AppColors.subtleSurface, expected);
  });
}
