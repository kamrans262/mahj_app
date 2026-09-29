import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/router/app_router.dart';
import 'package:mahj_app/features/settings/domain/legal_data.dart';
import 'package:mahj_app/features/settings/presentation/legal_screen.dart';
import 'package:mahj_app/features/settings/presentation/settings_screen.dart';

void main() {
  testWidgets('Settings Terms and Privacy rows open the shared Legal screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: Builder(
          builder: (context) => SettingsScreen(
            onTermsTap: () {
              Navigator.of(
                context,
              ).pushNamed(AppRoutes.legal, arguments: LegalDocumentType.terms);
            },
            onPrivacyPolicyTap: () {
              Navigator.of(context).pushNamed(
                AppRoutes.legal,
                arguments: LegalDocumentType.privacy,
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    final termsRow = find.byKey(const ValueKey('settings-row-terms'));
    await tester.ensureVisible(termsRow);
    await tester.pump();
    await tester.tap(termsRow);
    await tester.pumpAndSettle();

    expect(find.byType(LegalScreen), findsOneWidget);
    expect(find.text('Acceptance of Terms'), findsOneWidget);

    Navigator.of(tester.element(find.byType(LegalScreen))).pop();
    await tester.pumpAndSettle();

    final privacyRow = find.byKey(
      const ValueKey('settings-row-privacy-policy'),
    );
    await tester.ensureVisible(privacyRow);
    await tester.pump();
    await tester.tap(privacyRow);
    await tester.pumpAndSettle();

    expect(find.byType(LegalScreen), findsOneWidget);
    expect(find.text('Information We Collect'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
