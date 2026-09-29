import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_asset_icon.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../domain/auth_validators.dart';
import 'widgets/auth_background.dart';
import 'widgets/auth_divider.dart';
import 'widgets/auth_inline_action_prompt.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({
    super.key,
    this.isLoading = false,
    this.onSignUp,
    this.onGoogleSignUp,
    this.onAppleSignUp,
    this.onBack,
    this.onLogin,
  });

  final bool isLoading;
  final Future<void> Function(String fullName, String email, String password)?
  onSignUp;
  final VoidCallback? onGoogleSignUp;
  final VoidCallback? onAppleSignUp;
  final VoidCallback? onBack;
  final VoidCallback? onLogin;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _fullNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _isSubmitting = false;

  bool get _isBusy => widget.isLoading || _isSubmitting;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isBusy) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final callback = widget.onSignUp;
    if (callback == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await callback(
        _fullNameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AuthBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableHeight = math.max(0.0, constraints.maxHeight);
              final flexibleActionGap = (availableHeight - 656)
                  .clamp(
                    AppSpacing.signUpFlexibleGapMin,
                    AppSpacing.signUpFlexibleGapMax,
                  )
                  .toDouble();

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  bottom: keyboardInset > 0 ? AppSpacing.lg : 0,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: availableHeight),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Padding(
                        // Screen/body horizontal padding is intentionally applied
                        // once here. Full-width children add no page margin.
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.pageHorizontal,
                        ),
                        child: Form(
                          key: _formKey,
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: AppSpacing.signUpTop),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: AppBackButton(
                                    key: const ValueKey('signup-back-button'),
                                    onPressed: _isBusy ? null : widget.onBack,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                const Text(
                                  'Create Account',
                                  key: ValueKey('signup-heading'),
                                  textAlign: TextAlign.center,
                                  style: AppTypography.authHeading,
                                ),
                                const SizedBox(
                                  height: AppSpacing.signUpHeadingToForm,
                                ),
                                AppTextField(
                                  key: const ValueKey('full-name-field'),
                                  controller: _fullNameController,
                                  focusNode: _fullNameFocusNode,
                                  hintText: 'Full Name',
                                  leadingIcon: Icons.account_circle_outlined,
                                  keyboardType: TextInputType.name,
                                  textInputAction: TextInputAction.next,
                                  enabled: !_isBusy,
                                  autofillHints: const [AutofillHints.name],
                                  validator: AuthValidators.fullName,
                                  onFieldSubmitted: (_) {
                                    _emailFocusNode.requestFocus();
                                  },
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                AppTextField(
                                  key: const ValueKey('signup-email-field'),
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  hintText: 'E-mail',
                                  leadingIcon: Icons.mail_outline_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  enabled: !_isBusy,
                                  autofillHints: const [AutofillHints.email],
                                  validator: AuthValidators.email,
                                  onFieldSubmitted: (_) {
                                    _passwordFocusNode.requestFocus();
                                  },
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                AppTextField(
                                  key: const ValueKey('signup-password-field'),
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  hintText: 'Password',
                                  leadingIcon: Icons.lock_outline_rounded,
                                  textInputAction: TextInputAction.next,
                                  obscureText: true,
                                  enabled: !_isBusy,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  validator: AuthValidators.newPassword,
                                  onFieldSubmitted: (_) {
                                    _confirmPasswordFocusNode.requestFocus();
                                  },
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                AppTextField(
                                  key: const ValueKey('confirm-password-field'),
                                  controller: _confirmPasswordController,
                                  focusNode: _confirmPasswordFocusNode,
                                  hintText: 'Confirm Password',
                                  leadingIcon: Icons.lock_outline_rounded,
                                  textInputAction: TextInputAction.done,
                                  obscureText: true,
                                  enabled: !_isBusy,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  validator: (value) =>
                                      AuthValidators.confirmPassword(
                                        value,
                                        _passwordController.text,
                                      ),
                                  onFieldSubmitted: (_) => _submit(),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                const AuthDivider(),
                                const SizedBox(height: AppSpacing.lg),
                                AppButton.outlined(
                                  key: const ValueKey('google-signup-button'),
                                  label: 'Continue with Google',
                                  onPressed: _isBusy
                                      ? null
                                      : () => widget.onGoogleSignUp?.call(),
                                  leading: const AppAssetIcon(
                                    key: ValueKey('google-signup-icon'),
                                    assetPath: AppAssets.googleLoginIcon,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AppButton.outlined(
                                  key: const ValueKey('apple-signup-button'),
                                  label: 'Continue with Apple',
                                  onPressed: _isBusy
                                      ? null
                                      : () => widget.onAppleSignUp?.call(),
                                  leading: const AppAssetIcon(
                                    key: ValueKey('apple-signup-icon'),
                                    assetPath: AppAssets.appleLoginIcon,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(height: flexibleActionGap),
                                AppButton.primary(
                                  key: const ValueKey('signup-button'),
                                  label: 'Sign Up',
                                  onPressed: _submit,
                                  isLoading: _isBusy,
                                  isEnabled: !_isBusy,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                AuthInlineActionPrompt(
                                  message: 'Already have an account? ',
                                  actionLabel: 'Log In',
                                  enabled: !_isBusy,
                                  actionKey: const ValueKey('login-link'),
                                  onAction: widget.onLogin,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                              ],
                            ),
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
