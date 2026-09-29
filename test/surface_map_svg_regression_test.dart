import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/app_assets.dart';
import 'package:mahj_app/app/theme/app_colors.dart';
import 'package:mahj_app/core/widgets/app_button.dart';
import 'package:mahj_app/features/map/presentation/map_screen.dart';
import 'package:mahj_app/features/matches/presentation/create_match_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shared light surface is exact solid #FFFFFF', () {
    expect(AppColors.subtleSurface, const Color(0xFFFFFFFF));
    expect(AppColors.nearbyMatchCardSurface, const Color(0xFFFFFFFF));
  });

  test('match artwork extracted from match.svg is bundled', () async {
    expect(AppAssets.mapMatchMarkerIcon, AppAssets.bottomMatchesIcon);
    expect(AppAssets.mapMatchMarkerIcon, endsWith('match_render.png'));

    final data = await rootBundle.load(AppAssets.mapMatchMarkerIcon);
    expect(data.lengthInBytes, greaterThan(0));
  });

  testWidgets('Create Match Location Address is a real input', (tester) async {
    tester.view.physicalSize = const Size(820, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: CreateMatchScreen()));

    final locationField = find.widgetWithText(
      TextFormField,
      'Location/Address',
    );
    expect(locationField, findsOneWidget);

    await tester.enterText(locationField, '1001, New York, NY');

    final createButton = find.widgetWithText(AppButton, 'Create Match');
    expect(createButton, findsOneWidget);
    await tester.tap(createButton);
    await tester.pump();

    expect(find.text('Please select a match date.'), findsOneWidget);
  });

  testWidgets('Map canvas uses full available screen width', (tester) async {
    tester.view.physicalSize = const Size(820, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: MapScreen()));
    await tester.pumpAndSettle();

    final mapRect = tester.getRect(
      find.byKey(const ValueKey('map-full-width-slot')),
    );
    expect(mapRect.left, 0);
    expect(mapRect.width, 820);
  });
}
