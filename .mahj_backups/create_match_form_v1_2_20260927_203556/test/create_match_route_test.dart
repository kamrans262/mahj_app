import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/router/app_router.dart';

void main() {
  test('Create Match route is registered', () {
    expect(AppRoutes.createMatch, '/create-match');
    expect(AppRouter.routes, contains(AppRoutes.createMatch));
  });
}
