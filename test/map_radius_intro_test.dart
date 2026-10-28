import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/home/domain/match_filters.dart';
import 'package:mahj_app/features/map/data/map_radius_intro_store.dart';
import 'package:mahj_app/features/map/presentation/map_screen.dart';

class _MemoryMapRadiusIntroStore implements MapRadiusIntroStore {
  _MemoryMapRadiusIntroStore({this.shown = false});

  bool shown;
  int showWrites = 0;

  @override
  Future<bool> hasBeenShown() async => shown;

  @override
  Future<void> markShown() async {
    shown = true;
    showWrites++;
  }
}

class _SlowMapRadiusIntroStore extends _MemoryMapRadiusIntroStore {
  final Completer<bool> pendingRead = Completer<bool>();

  @override
  Future<bool> hasBeenShown() => pendingRead.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void prepareSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(820, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'First Map visit opens radius sheet exactly once, even after Cancel and reopening Map',
    (tester) async {
      prepareSize(tester);
      final store = _MemoryMapRadiusIntroStore();
      var filterUpdates = 0;

      await tester.pumpWidget(MaterialApp(
        home: MapScreen(
          key: const ValueKey('first-map-visit'),
          radiusIntroStore: store,
          onFiltersChanged: (_) async {
            filterUpdates++;
          },
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('map-radius-sheet')), findsOneWidget);
      expect(find.text('Select Radius'), findsOneWidget);
      expect(store.shown, isTrue);
      expect(store.showWrites, 1);
      expect(filterUpdates, 0);

      await tester.tap(find.byKey(const ValueKey('map-radius-cancel')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('map-radius-sheet')), findsNothing);
      expect(filterUpdates, 0);

      // A new MapScreen state represents leaving and returning to the tab.
      await tester.pumpWidget(MaterialApp(
        home: MapScreen(
          key: const ValueKey('second-map-visit'),
          radiusIntroStore: store,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('map-radius-sheet')), findsNothing);
      expect(store.showWrites, 1);

      // The miles chip must always remain a manual way to reopen the sheet.
      await tester.tap(find.text('10 miles'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('map-radius-sheet')), findsOneWidget);
      expect(store.showWrites, 2);
    },
  );

  testWidgets('First automatic radius selection updates filters and does not auto-repeat', (
    tester,
  ) async {
    prepareSize(tester);
    final store = _MemoryMapRadiusIntroStore();
    MatchFilters? applied;
    final radii = <int>[];

    await tester.pumpWidget(MaterialApp(
      home: MapScreen(
        key: const ValueKey('map-first-apply'),
        radiusIntroStore: store,
        onFiltersChanged: (filters) async {
          applied = filters;
        },
        onRadiusChanged: radii.add,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('map-radius-sheet')), findsOneWidget);

    tester.widget<Slider>(
      find.byKey(const ValueKey('mahj-radius-slider')),
    ).onChanged!(15);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('map-radius-apply')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('map-radius-sheet')), findsNothing);
    expect(applied?.radiusMiles, 15);
    expect(radii, [15]);
    expect(store.shown, isTrue);

    await tester.pumpWidget(MaterialApp(
      home: MapScreen(
        key: const ValueKey('map-after-first-apply'),
        radiusIntroStore: store,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('map-radius-sheet')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Previously introduced Map never opens automatically', (
    tester,
  ) async {
    prepareSize(tester);
    final store = _MemoryMapRadiusIntroStore(shown: true);
    await tester.pumpWidget(MaterialApp(
      home: MapScreen(radiusIntroStore: store),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('map-radius-sheet')), findsNothing);
    expect(store.showWrites, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A manual tap during initial storage read never opens two sheets', (
    tester,
  ) async {
    prepareSize(tester);
    final store = _SlowMapRadiusIntroStore();
    await tester.pumpWidget(MaterialApp(
      home: MapScreen(radiusIntroStore: store),
    ));
    await tester.pump();

    // The automatic intro is waiting for the saved preference.
    await tester.tap(find.text('10 miles'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('map-radius-sheet')), findsOneWidget);
    expect(store.showWrites, 1);

    store.pendingRead.complete(false);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('map-radius-sheet')), findsOneWidget);
    expect(store.showWrites, 1);
    expect(tester.takeException(), isNull);
  });
}
