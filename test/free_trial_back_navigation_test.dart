import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/router/app_router.dart';

void main() {
  testWidgets('Free trial back goes to login when OTP cleared navigation history', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => AppRouter.backFromPremiumPlan(context),
          child: const Text('Free trial back'),
        ),
      )),
      routes: {
        AppRoutes.login: (_) => const Scaffold(body: Text('Login destination')),
      },
    ));

    await tester.tap(find.text('Free trial back'));
    await tester.pumpAndSettle();

    expect(find.text('Login destination'), findsOneWidget);
    expect(find.text('Free trial back'), findsNothing);
  });

  testWidgets('Free trial back returns to previous route when possible', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (pageContext) => Scaffold(
              body: TextButton(
                onPressed: () => AppRouter.backFromPremiumPlan(pageContext),
                child: const Text('Free trial back'),
              ),
            ),
          )),
          child: const Text('Previous page'),
        ),
      )),
    ));

    await tester.tap(find.text('Previous page'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Free trial back'));
    await tester.pumpAndSettle();

    expect(find.text('Previous page'), findsOneWidget);
    expect(find.text('Free trial back'), findsNothing);
  });
}
