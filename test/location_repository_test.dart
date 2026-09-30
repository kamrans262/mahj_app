import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mahj_app/core/network/api_client.dart';
import 'package:mahj_app/core/storage/token_store.dart';
import 'package:mahj_app/features/home/data/location_repository.dart';

class _MemoryTokenStore implements TokenStore {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> read() async => 'test-token';

  @override
  Future<void> write(String token) async {}
}

void main() {
  test('location search maps structured backend results', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/locations/search');
      expect(request.url.queryParameters['q'], '10024');

      return http.Response(
        jsonEncode({
          'data': [
            {
              'label': 'New York, NY 10024, United States',
              'latitude': 40.785091,
              'longitude': -73.968285,
              'city': 'New York',
              'state': 'New York',
              'zip_code': '10024',
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final repository = LocationRepository(
      apiClient: ApiClient(
        baseUrl: 'https://example.com/api',
        tokenStore: _MemoryTokenStore(),
        httpClient: client,
      ),
    );

    final results = await repository.search('10024');

    expect(results, hasLength(1));
    expect(results.first.city, 'New York');
    expect(results.first.zipCode, '10024');
    expect(results.first.latitude, 40.785091);
    expect(results.first.longitude, -73.968285);
  });
}
