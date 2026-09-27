import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_asset_icon.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.isLoading = false,
    this.onLogin,
    this.onForgotPassword,
    this.onGoogleLogin,
    this.onAppleLogin,
    this.onSignUp,
  });

  final bool isLoading;
  final Future<void> Function(String email, String password)? onLogin;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onGoogleLogin;
  final VoidCallback? onAppleLogin;
  final VoidCallback? onSignUp;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final callback = widget.onLogin;
    if (callback == null) {
      return;
    }

    await callback(_emailController.text.trim(), _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = math.max(
              0.0,
              constraints.maxHeight - keyboardInset,
            );
            final flexibleLoginGap = (availableHeight - 650)
                .clamp(
                  AppSpacing.loginFlexibleGapMin,
                  AppSpacing.loginFlexibleGapMax,
                )
                .toDouble();

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(bottom: keyboardInset + AppSpacing.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: availableHeight),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pageHorizontal,
                      ),
                      child: Form(
                        key: _formKey,
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: AppSpacing.loginTop),
                              const Text(
                                'Welcome Back',
                                key: ValueKey('login-heading'),
                                textAlign: TextAlign.center,
                                style: AppTypography.loginHeading,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              const Text(
                                'Login to Continue',
                                textAlign: TextAlign.center,
                                style: AppTypography.loginSubtitle,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Center(
                                child: LayoutBuilder(
                                  builder: (context, imageConstraints) {
                                    final width = math.min(
                                      175.0,
                                      imageConstraints.maxWidth,
                                    );
                                    return SizedBox(
                                      width: width,
                                      child: AspectRatio(
                                        aspectRatio: 175 / 116,
                                        child: Image.asset(
                                          AppAssets.loginImage,
                                          key: const ValueKey('login-image'),
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.high,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AppTextField(
                                key: const ValueKey('email-field'),
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                hintText: 'E-mail',
                                leadingIcon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                enabled: !widget.isLoading,
                                autofillHints: const [AutofillHints.email],
                                validator: _validateEmail,
                                onFieldSubmitted: (_) {
                                  _passwordFocusNode.requestFocus();
                                },
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AppTextField(
                                key: const ValueKey('password-field'),
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                hintText: 'Password',
                                leadingIcon: Icons.lock_outline_rounded,
                                textInputAction: TextInputAction.done,
                                obscureText: true,
                                enabled: !widget.isLoading,
                                autofillHints: const [AutofillHints.password],
                                validator: _validatePassword,
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  key: const ValueKey('forgot-password'),
                                  onPressed: widget.isLoading
                                      ? null
                                      : () => widget.onForgotPassword?.call(),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    minimumSize: const Size(48, 44),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                      vertical: 8,
                                    ),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Forgot Password?',
                                    style: AppTypography.action14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              const _OrDivider(),
                              const SizedBox(height: AppSpacing.lg),
                              AppButton.outlined(
                                key: const ValueKey('google-login-button'),
                                label: 'Continue with Google',
                                onPressed: widget.isLoading
                                    ? null
                                    : () => widget.onGoogleLogin?.call(),
                                leading: const AppAssetIcon(
                                  key: ValueKey('google-login-icon'),
                                  assetPath: AppAssets.googleLoginIcon,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AppButton.outlined(
                                key: const ValueKey('apple-login-button'),
                                label: 'Continue with Apple',
                                onPressed: widget.isLoading
                                    ? null
                                    : () => widget.onAppleLogin?.call(),
                                leading: const AppAssetIcon(
                                  key: ValueKey('apple-login-icon'),
                                  assetPath: AppAssets.appleLoginIcon,
                                  size: 24,
                                ),
                              ),
                              SizedBox(height: flexibleLoginGap),
                              AppButton.primary(
                                key: const ValueKey('login-button'),
                                label: 'Log In',
                                onPressed: _submit,
                                isLoading: widget.isLoading,
                                isEnabled: !widget.isLoading,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _SignUpPrompt(
                                enabled: !widget.isLoading,
                                onSignUp: widget.onSignUp,
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
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Enter your email address';
    }

    final atIndex = email.indexOf('@');
    final dotIndex = email.lastIndexOf('.');
    if (atIndex <= 0 ||
        dotIndex <= atIndex + 1 ||
        dotIndex >= email.length - 1) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Enter your password';
    }
    return null;
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Or', style: AppTypography.muted14),
        ),
        const Expanded(child: Divider(color: AppColors.divider, height: 1)),
      ],
    );
  }
}

class _SignUpPrompt extends StatelessWidget {
  const _SignUpPrompt({required this.enabled, this.onSignUp});

  final bool enabled;
  final VoidCallback? onSignUp;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text("Don't have an account? ", style: AppTypography.body14),
        InkWell(
          key: const ValueKey('sign-up-link'),
          onTap: enabled ? () => onSignUp?.call() : null,
          borderRadius: BorderRadius.circular(6),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('Sign Up', style: AppTypography.action14),
          ),
        ),
      ],
    );
  }
}
