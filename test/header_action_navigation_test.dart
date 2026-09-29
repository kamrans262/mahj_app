import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/router/app_router.dart';
import 'package:mahj_app/features/chat/presentation/match_chat_screen.dart';
import 'package:mahj_app/features/matches/presentation/match_details_screen.dart';
import 'package:mahj_app/features/notifications/presentation/notifications_screen.dart';

const _homeNotificationsKey = ValueKey('home-header-notifications');
const _homeMessagesKey = ValueKey('home-header-messages');
const _myMatchesNotificationsKey = ValueKey('my-matches-header-notifications');
const _myMatchesMessagesKey = ValueKey('my-matches-header-messages');

void _setViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1;
}

Future<void> _pumpRoute(WidgetTester tester, String route) async {
  await tester.pumpWidget(
    MaterialApp(
      initialRoute: route,
      routes: AppRouter.routes,
      onGenerateRoute: AppRouter.onGenerateRoute,
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('Home bell opens Notifications and notification opens match', (
    tester,
  ) async {
    _setViewport(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpRoute(tester, AppRoutes.home);

    expect(find.byKey(_homeNotificationsKey), findsOneWidget);
    await tester.tap(find.byKey(_homeNotificationsKey));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    final notificationItem = find.byKey(
      const ValueKey('notification-item-demo-notification-1'),
    );
    expect(notificationItem, findsOneWidget);
    await tester.tap(notificationItem);
    await tester.pumpAndSettle();

    expect(find.byType(MatchDetailsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home header message icon opens Match Chat', (tester) async {
    _setViewport(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpRoute(tester, AppRoutes.home);

    expect(find.byKey(_homeMessagesKey), findsOneWidget);
    await tester.tap(find.byKey(_homeMessagesKey));
    await tester.pumpAndSettle();
    expect(find.byType(MatchChatScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('My Matches bell opens Notifications', (tester) async {
    _setViewport(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpRoute(tester, AppRoutes.myMatches);

    expect(find.byKey(_myMatchesNotificationsKey), findsOneWidget);
    await tester.tap(find.byKey(_myMatchesNotificationsKey));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('My Matches header message icon opens Match Chat', (
    tester,
  ) async {
    _setViewport(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpRoute(tester, AppRoutes.myMatches);

    expect(find.byKey(_myMatchesMessagesKey), findsOneWidget);
    await tester.tap(find.byKey(_myMatchesMessagesKey));
    await tester.pumpAndSettle();
    expect(find.byType(MatchChatScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
