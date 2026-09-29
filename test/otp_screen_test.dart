import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/theme/app_theme.dart';
import 'package:mahj_app/features/auth/domain/auth_flow_args.dart';
import 'package:mahj_app/features/auth/presentation/otp_screen.dart';

void main() {
  Future<void> pumpOtp(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    Future<bool> Function(String otp)? onVerify,
    Future<bool> Function()? onResend,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: OtpScreen(
          email: 'player@example.com',
          purpose: OtpPurpose.registration,
          onVerify: onVerify,
          onResend: onResend,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('OTP screen is centered with six square code boxes', (
    tester,
  ) async {
    await pumpOtp(tester);

    expect(find.byKey(const ValueKey('otp-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('otp-heading')), findsOneWidget);
    expect(find.text('Verify Your Email'), findsOneWidget);
    expect(find.byKey(const ValueKey('otp-box-row')), findsOneWidget);

    for (var index = 0; index < 6; index++) {
      final size = tester.getSize(find.byKey(ValueKey('otp-box-$index')));
      expect(size.width, size.height);
      expect(size.width, 48);
    }

    final row = tester.getRect(find.byKey(const ValueKey('otp-box-row')));
    expect(row.center.dx, closeTo(195, 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('OTP boxes remain square on a compact phone', (tester) async {
    await pumpOtp(tester, size: const Size(320, 568));

    for (var index = 0; index < 6; index++) {
      final size = tester.getSize(find.byKey(ValueKey('otp-box-$index')));
      expect(size.width, size.height);
      expect(size.width, greaterThanOrEqualTo(36));
      expect(size.width, lessThanOrEqualTo(48));
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('six digit code is submitted once through verify action', (
    tester,
  ) async {
    String? submittedCode;

    await pumpOtp(
      tester,
      onVerify: (otp) async {
        submittedCode = otp;
        return true;
      },
    );

    await tester.enterText(
      find.byKey(const ValueKey('otp-input')),
      '123456',
    );
    await tester.tap(find.byKey(const ValueKey('otp-verify-button')));
    await tester.pumpAndSettle();

    expect(submittedCode, '123456');
    expect(find.text('1'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resend callback clears entered code after success', (
    tester,
  ) async {
    var resendCount = 0;

    await pumpOtp(
      tester,
      onResend: () async {
        resendCount++;
        return true;
      },
    );

    await tester.enterText(
      find.byKey(const ValueKey('otp-input')),
      '123456',
    );
    await tester.tap(find.byKey(const ValueKey('otp-resend-button')));
    await tester.pumpAndSettle();

    expect(resendCount, 1);
    expect(
      tester.widget<TextField>(find.byKey(const ValueKey('otp-input'))).controller?.text,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });
}
