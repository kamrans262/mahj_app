import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_asset_icon.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../domain/auth_validators.dart';
import 'widgets/auth_background.dart';
import 'widgets/auth_submit_icon_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    this.onBack,
    this.onBackToLogin,
    this.onSendResetLink,
  });

  final VoidCallback? onBack;
  final VoidCallback? onBackToLogin;
  final Future<bool> Function(String email)? onSendResetLink;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const double _contentMaxWidth = 480;
  static const double _subtitleMaxWidth = 300;
  static const double _lockWidth = 96;
  static const double _lockHeight = 133;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();

  bool _isSubmitting = false;
  bool _resetLinkSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final callback = widget.onSendResetLink;
    if (callback == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final succeeded = await callback(_emailController.text.trim());
      if (!mounted) {
        return;
      }
      setState(() {
        _resetLinkSent = succeeded;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AuthBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = math.min(
                constraints.maxWidth,
                _contentMaxWidth,
              );

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: contentWidth,
                      maxWidth: contentWidth,
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.all(
                          AppSpacing.pageHorizontal,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: AppBackButton(
                                  key: const ValueKey('forgot-back-button'),
                                  onPressed: _isSubmitting
                                      ? null
                                      : widget.onBack,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              const Text(
                                'Forgot Password?',
                                key: ValueKey('forgot-password-heading'),
                                textAlign: TextAlign.center,
                                style: AppTypography.authHeading,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              const Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: _subtitleMaxWidth,
                                  ),
                                  child: Text(
                                    'Enter your email and we’ll send you a reset link',
                                    key: ValueKey('forgot-password-subtitle'),
                                    textAlign: TextAlign.center,
                                    style: AppTypography.loginSubtitle,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Center(
                                child: SizedBox(
                                  key: const ValueKey(
                                    'forgot-lock-image-frame',
                                  ),
                                  width: _lockWidth,
                                  height: _lockHeight,
                                  child: Image.asset(
                                    AppAssets.forgotPasswordLock,
                                    key: const ValueKey('forgot-lock-image'),
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Row(
                                key: const ValueKey('forgot-email-row'),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      key: const ValueKey('forgot-email-field'),
                                      controller: _emailController,
                                      focusNode: _emailFocusNode,
                                      hintText: 'Enter your E-mail',
                                      leadingIcon: Icons.mail_outline_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.done,
                                      enabled: !_isSubmitting,
                                      autofillHints: const [
                                        AutofillHints.email,
                                      ],
                                      validator: AuthValidators.email,
                                      onFieldSubmitted: (_) => _submit(),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  AuthSubmitIconButton(
                                    key: const ValueKey('forgot-send-button'),
                                    onPressed: _submit,
                                    assetPath: AppAssets.resetSendIcon,
                                    isLoading: _isSubmitting,
                                  ),
                                ],
                              ),
                              if (_resetLinkSent) ...[
                                const SizedBox(height: AppSpacing.lg),
                                const _ResetLinkSentCard(),
                              ],
                              const Spacer(),
                              AppButton.primary(
                                key: const ValueKey('send-reset-link-button'),
                                label: 'Send Reset Link',
                                onPressed: _submit,
                                isLoading: _isSubmitting,
                                isEnabled: !_isSubmitting,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AppButton.secondary(
                                key: const ValueKey('back-to-login-button'),
                                label: 'Back to Login',
                                onPressed: _isSubmitting
                                    ? null
                                    : widget.onBackToLogin,
                                isEnabled: !_isSubmitting,
                              ),
                            ],
                          ),
                        ),
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

class _ResetLinkSentCard extends StatelessWidget {
  const _ResetLinkSentCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('reset-link-sent-card'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.authSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.navigationButtonBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppAssetIcon(
            key: ValueKey('reset-link-approved-icon'),
            assetPath: AppAssets.approveIcon,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.iconGap),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reset Link Sent', style: AppTypography.successTitle),
                SizedBox(height: AppSpacing.micro),
                Text(
                  'we’ve sent a password reset link to your email',
                  style: AppTypography.body14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
