import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mahj_app/core/network/api_client.dart';
import 'package:mahj_app/core/storage/token_store.dart';
import 'package:mahj_app/features/home/data/home_preview_data.dart';
import 'package:mahj_app/features/home/presentation/home_screen.dart';
import 'package:mahj_app/features/home/presentation/widgets/home_header.dart';
import 'package:mahj_app/features/home/presentation/widgets/section_header.dart';
import 'package:mahj_app/features/matches/data/match_repository.dart';
import 'package:mahj_app/features/navigation/presentation/main_navigation_shell.dart';
import 'package:mahj_app/features/profile/data/profile_preview_data.dart';

void main() {
  testWidgets('logged-in Home greeting says Hello with first name only', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = MatchRepository(
      apiClient: ApiClient(
        baseUrl: 'https://example.test/api',
        tokenStore: SecureTokenStore(useMemoryOnly: true),
        httpClient: MockClient((request) async =>
            http.Response('{"data":[]}', 200)),
      ),
    );

    await tester.pumpWidget(MaterialApp(
      home: MainNavigationShell(
        matchRepository: repository,
        initialProfileData:
            ProfilePreviewData.currentUser.copyWith(name: 'Jerry Wilson'),
      ),
    ));
    await tester.pump();

    final greeting = tester.widget<HomeHeader>(find.byType(HomeHeader));
    expect(greeting.displayName, 'Jerry');
    expect(greeting.greeting, 'Hello');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Upcoming Matches hides View All; Nearby Matches keeps its action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var nearbyOpened = false;
    await tester.pumpWidget(MaterialApp(
      home: HomeScreen(
        data: HomePreviewData.create(),
        onUpcomingViewAll: () {
          fail('Upcoming Matches should never expose View All');
        },
        onNearbyViewAll: () => nearbyOpened = true,
      ),
    ));
    await tester.pump();

    final upcoming = find.byWidgetPredicate(
      (widget) => widget is SectionHeader && widget.title == 'Upcoming Matches',
    );
    final nearby = find.byWidgetPredicate(
      (widget) => widget is SectionHeader && widget.title == 'Nearby Matches',
    );

    expect(upcoming, findsOneWidget);
    expect(find.descendant(of: upcoming, matching: find.text('View All')),
        findsNothing);
    expect(find.descendant(of: nearby, matching: find.text('View All')),
        findsOneWidget);

    await tester.tap(find.descendant(
      of: nearby,
      matching: find.text('View All'),
    ));
    expect(nearbyOpened, isTrue);
    expect(tester.takeException(), isNull);
  });
}
