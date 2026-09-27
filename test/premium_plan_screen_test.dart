import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/theme/app_theme.dart';
import 'package:mahj_app/features/premium/presentation/premium_plan_screen.dart';

void main() {
  Future<void> pumpPremium(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
    PremiumPlanScreen screen = const PremiumPlanScreen(),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: screen,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('premium screen exposes required content', (tester) async {
    await pumpPremium(tester);

    expect(find.byKey(const ValueKey('premium-back-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('premium-crown-badge')), findsOneWidget);
    expect(find.text('Start your 14 day free trial'), findsOneWidget);
    expect(find.text('See available matches close to you'), findsOneWidget);
    expect(find.text('Create and join matches'), findsOneWidget);
    expect(find.text('Chat with Players'), findsOneWidget);
    expect(find.byKey(const ValueKey('monthly-plan-card')), findsOneWidget);
    expect(find.text(r'$0.00'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('start-free-trial-button')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('premium-legal-footer')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('page-level horizontal padding is exactly 20 logical pixels', (
    tester,
  ) async {
    await pumpPremium(tester);

    final cardRect = tester.getRect(
      find.byKey(const ValueKey('monthly-plan-card')),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('start-free-trial-button')),
    );
    final buttonRect = tester.getRect(
      find.byKey(const ValueKey('start-free-trial-button')),
    );

    expect(cardRect.left, 20);
    expect(cardRect.right, 370);
    expect(buttonRect.left, 20);
    expect(buttonRect.right, 370);
  });

  testWidgets('approve icons render at exactly 24 by 24', (tester) async {
    await pumpPremium(tester);

    for (final key in const [
      ValueKey('premium-approve-1'),
      ValueKey('premium-approve-2'),
      ValueKey('premium-approve-3'),
    ]) {
      expect(tester.getSize(find.byKey(key)), const Size.square(24));
    }
  });

  testWidgets('crown badge has stable 48 by 48 visual bounds', (tester) async {
    await pumpPremium(tester);

    expect(
      tester.getSize(find.byKey(const ValueKey('premium-crown-badge'))),
      const Size.square(48),
    );
  });

  testWidgets('compact viewport remains scroll-safe', (tester) async {
    await pumpPremium(tester, size: const Size(320, 568));

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -550),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('start-free-trial-button')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('premium-legal-footer')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('larger accessibility text remains scroll-safe', (tester) async {
    await pumpPremium(tester, size: const Size(320, 568), textScale: 1.35);

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back and free-trial callbacks are connected', (tester) async {
    var backTapped = false;
    var trialTapped = false;

    await pumpPremium(
      tester,
      screen: PremiumPlanScreen(
        onBack: () => backTapped = true,
        onStartFreeTrial: () async => trialTapped = true,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('premium-back-button')));
    await tester.pump();
    expect(backTapped, isTrue);

    await tester.ensureVisible(
      find.byKey(const ValueKey('start-free-trial-button')),
    );
    await tester.tap(find.byKey(const ValueKey('start-free-trial-button')));
    await tester.pumpAndSettle();
    expect(trialTapped, isTrue);
  });
}
