import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_button.dart';
import '../domain/auth_flow_args.dart';
import 'widgets/auth_background.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    required this.email,
    required this.purpose,
    super.key,
    this.onBack,
    this.onVerify,
    this.onResend,
  });

  final String email;
  final OtpPurpose purpose;
  final VoidCallback? onBack;
  final Future<bool> Function(String otp)? onVerify;
  final Future<bool> Function()? onResend;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_refreshBoxes);
    _otpFocusNode.addListener(_refreshBoxes);
  }

  @override
  void dispose() {
    _otpController.removeListener(_refreshBoxes);
    _otpFocusNode.removeListener(_refreshBoxes);
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _refreshBoxes() {
    if (mounted) setState(() {});
  }

  Future<void> _verify() async {
    if (_isVerifying || _isResending) return;

    final code = _otpController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Enter the 6-digit verification code.')),
        );
      _otpFocusNode.requestFocus();
      return;
    }

    final callback = widget.onVerify;
    if (callback == null) return;

    setState(() => _isVerifying = true);
    try {
      await callback(code);
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    if (_isVerifying || _isResending) return;

    final callback = widget.onResend;
    if (callback == null) return;

    setState(() => _isResending = true);
    try {
      final sent = await callback();
      if (!mounted || !sent) return;

      _otpController.clear();
      _otpFocusNode.requestFocus();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('A new verification code has been sent.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRegistration = widget.purpose == OtpPurpose.registration;
    final title = isRegistration
        ? 'Verify Your Email'
        : 'Enter Verification Code';
    final subtitle = 'We sent a 6-digit verification code to\n${widget.email}';

    return Scaffold(
      key: const ValueKey('otp-screen'),
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      body: AuthBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = math.min(constraints.maxWidth, 480.0);
              final centerGap = (constraints.maxHeight * 0.10)
                  .clamp(40.0, 88.0)
                  .toDouble();

              return SingleChildScrollView(
                key: const ValueKey('otp-scroll-view'),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                      maxWidth: contentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: AppBackButton(
                              key: const ValueKey('otp-back-button'),
                              onPressed: _isVerifying || _isResending
                                  ? null
                                  : widget.onBack,
                            ),
                          ),
                          SizedBox(height: centerGap),
                          Text(
                            title,
                            key: const ValueKey('otp-heading'),
                            textAlign: TextAlign.center,
                            style: AppTypography.authHeading,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            subtitle,
                            key: const ValueKey('otp-subtitle'),
                            textAlign: TextAlign.center,
                            style: AppTypography.loginSubtitle.copyWith(
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 36),
                          _OtpInput(
                            controller: _otpController,
                            focusNode: _otpFocusNode,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          AppButton.primary(
                            key: const ValueKey('otp-verify-button'),
                            label: 'Verify Code',
                            onPressed: _verify,
                            isLoading: _isVerifying,
                            isEnabled: !_isResending,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Center(
                            child: TextButton(
                              key: const ValueKey('otp-resend-button'),
                              onPressed: _isVerifying || _isResending
                                  ? null
                                  : _resend,
                              child: Text(
                                _isResending
                                    ? 'Sending...'
                                    : "Didn't receive the code? Resend",
                                textAlign: TextAlign.center,
                                style: AppTypography.action14,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OtpInput extends StatelessWidget {
  const _OtpInput({required this.controller, required this.focusNode});

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: '6-digit verification code',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (focusNode.hasFocus) {
            SystemChannels.textInput.invokeMethod<void>('TextInput.show');
          } else {
            focusNode.requestFocus();
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: 0,
              child: SizedBox(
                width: 20,
                height: 20,
                child: TextField(
                  key: const ValueKey('otp-input'),
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  style: const TextStyle(fontSize: 1),
                  cursorWidth: 0.1,
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    counterText: '',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 328),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const gap = AppSpacing.xs;
                  final availableForBoxes = constraints.maxWidth - (gap * 5);
                  final boxSize = (availableForBoxes / 6)
                      .clamp(36.0, 48.0)
                      .toDouble();

                  return Row(
                    key: const ValueKey('otp-box-row'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final text = controller.text;
                      final digit = index < text.length ? text[index] : '';
                      final activeIndex = math.min(text.length, 5);
                      final active = focusNode.hasFocus && index == activeIndex;

                      return Padding(
                        padding: EdgeInsets.only(right: index == 5 ? 0 : gap),
                        child: AnimatedContainer(
                          key: ValueKey('otp-box-$index'),
                          duration: const Duration(milliseconds: 120),
                          width: boxSize,
                          height: boxSize,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(
                              AppRadius.control,
                            ),
                            border: Border.all(
                              color: active || digit.isNotEmpty
                                  ? AppColors.primary
                                  : AppColors.controlBorder,
                              width: active ? 1.5 : 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.controlShadow,
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            digit,
                            style: AppTypography.title18.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
