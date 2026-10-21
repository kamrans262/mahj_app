import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/home/domain/discovery_location.dart';
import 'package:mahj_app/features/home/domain/match_filters.dart';
import 'package:mahj_app/features/home/presentation/widgets/home_filter_sheet.dart';

void main() {
  testWidgets('Home filter date and location fields have equal height; radius has no dots', (tester) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HomeFilterSheet(
          initialFilters: MatchFilters.defaults(),
          onApply: (_) async {},
          onLocationSearch: (_) async => const <DiscoveryLocation>[],
          onCurrentLocation: () async => const DiscoveryLocation.current(
            latitude: 40.78,
            longitude: -73.97,
          ),
        ),
      ),
    ));
    await tester.pump();

    final locationField = find.byKey(const ValueKey('home-filter-location-field'));
    final dateField = find.byKey(const ValueKey('home-filter-date-field'));
    expect(locationField, findsOneWidget);
    expect(dateField, findsOneWidget);
    expect(tester.getSize(locationField).height, 48);
    expect(tester.getSize(dateField).height, tester.getSize(locationField).height);

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.divisions, 49);
    expect(slider.max, 50);
    final sliderTheme = tester.widget<SliderTheme>(
      find.ancestor(of: find.byType(Slider), matching: find.byType(SliderTheme)).first,
    );
    expect(sliderTheme.data.tickMarkShape, SliderTickMarkShape.noTickMark);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home filter date remains selectable with matched height', (tester) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HomeFilterSheet(
          initialFilters: MatchFilters.defaults(),
          onApply: (_) async {},
          onLocationSearch: (_) async => const <DiscoveryLocation>[],
          onCurrentLocation: () async => const DiscoveryLocation.current(
            latitude: 40.78,
            longitude: -73.97,
          ),
        ),
      ),
    ));

    await tester.tap(find.byType(DropdownButton<MatchDateFilter>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tomorrow').last);
    await tester.pumpAndSettle();

    final dropdown = tester.widget<DropdownButton<MatchDateFilter>>(
      find.byType(DropdownButton<MatchDateFilter>),
    );
    expect(dropdown.value, MatchDateFilter.tomorrow);
    expect(tester.takeException(), isNull);
  });
}
