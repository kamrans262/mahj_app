import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/router/app_router.dart';
import 'package:mahj_app/features/subscription/presentation/manage_subscription_screen.dart';

void main() {
  testWidgets('Settings Subscription row opens Manage Subscription', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.settings,
        routes: AppRouter.routes,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pump();

    final subscription = find.byKey(
      const ValueKey('settings-row-subscription'),
    );
    expect(subscription, findsOneWidget);
    await tester.tap(subscription);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(ManageSubscriptionScreen), findsOneWidget);
    expect(find.text('Manage Subscription'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
