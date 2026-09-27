import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/router/app_router.dart';
import 'package:mahj_app/features/home/domain/home_match.dart';

void main() {
  test('Map route is registered', () {
    expect(AppRoutes.map, '/map');
    expect(AppRouter.routes, contains(AppRoutes.map));
  });

  test('Match details route accepts the selected HomeMatch', () {
    final match = HomeMatch(
      id: 'route-match',
      sportName: 'Football',
      location: 'Central Park',
      startsAt: DateTime(2026, 9, 28, 18),
      currentPlayers: 2,
      maxPlayers: 4,
      status: MatchStatus.open,
    );

    final route = AppRouter.onGenerateRoute(
      RouteSettings(
        name: AppRoutes.matchDetails,
        arguments: match,
      ),
    );

    expect(route, isNotNull);
  });
}
