import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/theme/app_colors.dart';
import 'package:mahj_app/core/widgets/app_icon_action_button.dart';
import 'package:mahj_app/core/widgets/app_surface_container.dart';
import 'package:mahj_app/core/widgets/app_text_field.dart';
import 'package:mahj_app/features/home/presentation/widgets/location_selector.dart';
import 'package:mahj_app/features/matches/presentation/create_match_screen.dart';

void main() {
  test('shared input surface token is solid #FFFFFF', () {
    expect(AppColors.subtleSurface, const Color(0xFFFFFFFF));
  });

  testWidgets('shared search field uses solid #FFFFFF', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppTextField(
            controller: controller,
            hintText: 'Search match or venues',
            leadingIcon: Icons.search,
          ),
        ),
      ),
    );

    final decorator = tester.widget<InputDecorator>(
      find.byType(InputDecorator),
    );
    expect(decorator.decoration.fillColor, AppColors.subtleSurface);
  });

  testWidgets('location selector uses shared #FFFFFF surface', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LocationSelector(location: '1001, New York, NY')),
      ),
    );

    final materials = tester.widgetList<Material>(find.byType(Material));
    expect(
      materials.any((material) => material.color == AppColors.subtleSurface),
      isTrue,
    );
  });

  testWidgets('send action uses shared #FFFFFF surface', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppIconActionButton(onPressed: () {}, fallbackIcon: Icons.send),
        ),
      ),
    );

    final materials = tester.widgetList<Material>(find.byType(Material));
    expect(
      materials.any((material) => material.color == AppColors.subtleSurface),
      isTrue,
    );
  });

  testWidgets('Create Match date and time pickers use AppSurfaceContainer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(820, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: CreateMatchScreen()));

    expect(find.byType(AppSurfaceContainer), findsNWidgets(2));
    expect(find.text('Date'), findsOneWidget);
    expect(find.text('Time'), findsOneWidget);
  });
}
