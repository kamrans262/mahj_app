import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/theme/app_colors.dart';
import 'package:mahj_app/app/theme/app_theme.dart';
import 'package:mahj_app/core/widgets/app_surface_container.dart';
import 'package:mahj_app/core/widgets/app_text_field.dart';

void main() {
  const white = Color(0xFFFFFFFF);

  test('all Mahj shared light surface tokens are pure white', () {
    expect(AppColors.background, white);
    expect(AppColors.navigationButtonBackground, white);
    expect(AppColors.authSurface, white);
    expect(AppColors.nearbyMatchCardSurface, white);
    expect(AppColors.subtleSurface, white);
    expect(AppColors.matchSuccessCardSurface, white);
    expect(AppColors.dialogInputSurface, white);
    expect(AppTheme.light.scaffoldBackgroundColor, white);
  });

  testWidgets('reusable input field and surface container render white', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              AppTextField(controller: controller, hintText: 'Test field'),
              const AppSurfaceContainer(child: Text('Surface')),
            ],
          ),
        ),
      ),
    );

    final decorator = tester.widget<InputDecorator>(
      find.byType(InputDecorator),
    );
    expect(decorator.decoration.filled, isTrue);
    expect(decorator.decoration.fillColor, white);

    final materials = tester.widgetList<Material>(
      find.descendant(
        of: find.byType(AppSurfaceContainer),
        matching: find.byType(Material),
      ),
    );
    expect(materials.any((material) => material.color == white), isTrue);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(
      scaffold.backgroundColor ?? AppTheme.light.scaffoldBackgroundColor,
      white,
    );
  });

  test('legacy FFFDFC surface color is absent from lib', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final content = entity.readAsStringSync().toUpperCase();
      if (content.contains('FFFDFC')) offenders.add(entity.path);
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Legacy #FFFDFC references remain: ${offenders.join(', ')}',
    );
  });
}
