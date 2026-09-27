import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/router/app_router.dart';

void main() {
  test('home route is registered', () {
    expect(AppRouter.routes.containsKey(AppRoutes.home), isTrue);
  });
}
