import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/app_assets.dart';
import 'package:mahj_app/app/theme/app_colors.dart';
import 'package:mahj_app/core/widgets/app_asset_icon.dart';
import 'package:mahj_app/features/home/domain/home_match.dart';
import 'package:mahj_app/features/map/presentation/map_screen.dart';
import 'package:mahj_app/features/matches/presentation/match_details_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  HomeMatch createMatch() {
    return HomeMatch(
      id: 'details-test-match',
      sportName: 'Football',
      location: 'Central Park View',
      startsAt: DateTime(2026, 5, 25, 18),
      currentPlayers: 2,
      maxPlayers: 4,
      status: MatchStatus.open,
      latitude: 30.1575,
      longitude: 71.5249,
    );
  }

  testWidgets(
    'Match Details is scrollable and overflow-safe on a small phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(home: MatchDetailsScreen(match: createMatch())),
      );
      await tester.pump();

      expect(find.text('Match Details'), findsOneWidget);
      expect(find.text('Central Park View'), findsOneWidget);
      expect(find.text('Tomorrow, May 25'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(find.text('Join Match'), 180);

      expect(find.text('Join Match'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Edit Match sits immediately above Cancel Match in host actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 930);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var editPressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MatchDetailsScreen(
          match: createMatch().copyWith(
            canCancel: true,
            isOwnedByCurrentUser: true,
          ),
          canCancelMatch: true,
          onEditMatch: () => editPressed = true,
        ),
      ),
    );
    await tester.pump();

    final edit = find.byKey(const ValueKey('match-details-edit-match'));
    final cancel = find.text('Cancel Match');
    expect(edit, findsOneWidget);
    expect(cancel, findsOneWidget);

    await tester.ensureVisible(cancel);
    await tester.pump();

    final editRect = tester.getRect(edit);
    final cancelRect = tester.getRect(cancel);
    expect(editRect.bottom, lessThan(cancelRect.top));

    await tester.ensureVisible(edit);
    await tester.tap(edit);
    expect(editPressed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Match Details uses the supplied live-map marker artwork', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: MatchDetailsScreen(match: createMatch())),
    );
    await tester.pump();

    final marker = tester.widget<Image>(
      find.byKey(const ValueKey('match-details-map-marker')),
    );
    final image = marker.image as AssetImage;

    expect(image.assetName, AppAssets.mapMatchMarkerPng);
  });

  testWidgets('Map screen metadata icons and match markers use app grey', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(820, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: MapScreen()));
    await tester.pump();

    final calendar = tester.widget<Icon>(find.byIcon(Icons.calendar_today));
    final clock = tester.widget<Icon>(find.byIcon(Icons.access_time));

    expect(calendar.color, AppColors.textSecondary);
    expect(clock.color, AppColors.textSecondary);

    final firstMarker = find.byKey(
      const ValueKey('map-marker-map-preview-basketball-1'),
    );
    final markerIcon = tester.widget<AppAssetIcon>(
      find.descendant(of: firstMarker, matching: find.byType(AppAssetIcon)),
    );

    expect(markerIcon.color, AppColors.textSecondary);
  });
}
