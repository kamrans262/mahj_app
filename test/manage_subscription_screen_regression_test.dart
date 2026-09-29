import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/subscription/data/subscription_preview_data.dart';
import 'package:mahj_app/features/subscription/presentation/manage_subscription_screen.dart';

void main() {
  testWidgets(
    'Manage Subscription renders state-driven plans without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: ManageSubscriptionScreen(
            currentPlan: SubscriptionPreviewData.currentPlan,
            availablePlans: SubscriptionPreviewData.availablePlans,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Manage Subscription'), findsOneWidget);
      expect(find.text('Current Plan'), findsOneWidget);
      expect(find.text('Choose Your Plan'), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('14- Day Free Trial'), findsOneWidget);
      expect(find.text('Monthly Plan'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('manage-subscription-confirm')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Confirm Changes opens popup before subscription callback', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var submitCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ManageSubscriptionScreen(
          currentPlan: SubscriptionPreviewData.currentPlan,
          availablePlans: SubscriptionPreviewData.availablePlans,
          onConfirmChange: (plan) async {
            submitCalls++;
            return true;
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('subscription-plan-monthly')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('manage-subscription-confirm')));
    await tester.pump(const Duration(milliseconds: 220));

    expect(
      find.text('Are you sure you want to switch to the Monthly Plan?'),
      findsOneWidget,
    );
    expect(submitCalls, 0);

    await tester.tap(find.byKey(const ValueKey('confirmation-confirm-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(submitCalls, 1);
    expect(
      find.text('Are you sure you want to switch to the Monthly Plan?'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Manage Subscription remains usable on a short narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ManageSubscriptionScreen(
          currentPlan: SubscriptionPreviewData.currentPlan,
          availablePlans: SubscriptionPreviewData.availablePlans,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('manage-subscription-confirm')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('manage-subscription-scroll-view')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
