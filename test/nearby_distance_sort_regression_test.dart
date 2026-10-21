import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mahj_app/core/network/api_client.dart';
import 'package:mahj_app/core/storage/token_store.dart';
import 'package:mahj_app/features/home/data/match_discovery_store.dart';
import 'package:mahj_app/features/home/domain/match_filters.dart';
import 'package:mahj_app/features/home/presentation/connected_nearby_matches_screen.dart';
import 'package:mahj_app/features/home/presentation/widgets/match_card.dart';
import 'package:mahj_app/features/matches/data/match_repository.dart';

class _MemoryTokenStore implements TokenStore {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> read() async => 'test-token';

  @override
  Future<void> write(String token) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Nearby Match distance sort uses coordinates and can switch to date', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final filters = MatchFilters.defaults().copyWith(
      selectedLocation: 'Central Park, New York',
      latitude: 40.785091,
      longitude: -73.968285,
    );
    final store = MatchDiscoveryStore()..update(filters, notify: false);
    addTearDown(store.dispose);

    final sorts = <String>[];
    final client = MockClient((request) async {
      final query = request.url.queryParameters;
      sorts.add(query['sort'] ?? '');
      expect(query['latitude'], '40.7850910');
      expect(query['longitude'], '-73.9682850');
      expect(query['radius_miles'], '6');

      Map<String, dynamic> item(String id, String place, double distance) => {
        'id': id,
        'sport_name': 'Mah Jongg',
        'location': place,
        'starts_at': DateTime.now().add(const Duration(days: 2)).toUtc().toIso8601String(),
        'current_players': 1,
        'max_players': 4,
        'status': 'open',
        'distance_miles': distance,
      };
      final near = item('near', 'Near Court', 2);
      final far = item('far', 'Far Court', 18);
      return http.Response(
        jsonEncode({'data': query['sort'] == 'distance' ? [near, far] : [far, near]}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repository = MatchRepository(
      apiClient: ApiClient(
        baseUrl: 'https://example.com/api',
        tokenStore: _MemoryTokenStore(),
        httpClient: client,
      ),
    );

    await tester.pumpWidget(MaterialApp(
      home: ConnectedNearbyMatchesScreen(
        repository: repository,
        discoveryStore: store,
      ),
    ));
    await tester.pumpAndSettle();

    expect(sorts.last, 'distance');
    expect(tester.widgetList<MatchCard>(find.byType(MatchCard)).first.match.id, 'near');

    await tester.tap(find.text('Sort: Distance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Date').last);
    await tester.pumpAndSettle();

    expect(sorts.last, 'date');
    expect(tester.widgetList<MatchCard>(find.byType(MatchCard)).first.match.id, 'far');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Missing location does not silently claim successful distance sorting', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final client = MockClient((request) async {
      expect(request.url.queryParameters['sort'], 'date');
      expect(request.url.queryParameters.containsKey('latitude'), isFalse);
      return http.Response(jsonEncode({'data': []}), 200,
          headers: {'content-type': 'application/json'});
    });
    final repository = MatchRepository(
      apiClient: ApiClient(
        baseUrl: 'https://example.com/api',
        tokenStore: _MemoryTokenStore(),
        httpClient: client,
      ),
    );

    await tester.pumpWidget(MaterialApp(
      home: ConnectedNearbyMatchesScreen(repository: repository),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Select a city or ZIP code'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
