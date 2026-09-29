import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/router/app_router.dart';
import 'package:mahj_app/features/settings/presentation/support_screen.dart';

void main() {
  testWidgets('Settings Support row opens SupportScreen', (tester) async {
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

    final row = find.byKey(const ValueKey('settings-row-support'));
    expect(row, findsOneWidget);
    await tester.tap(row);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(SupportScreen), findsOneWidget);
    final supportScreen = find.byKey(const ValueKey('support-screen'));
    expect(supportScreen, findsOneWidget);
    expect(
      find.descendant(of: supportScreen, matching: find.text('Support')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings FAQs row reuses the Support screen', (tester) async {
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

    final row = find.byKey(const ValueKey('settings-row-faqs'));
    expect(row, findsOneWidget);
    await tester.tap(row);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(SupportScreen), findsOneWidget);
    expect(find.text('Frequently Asked Questions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
