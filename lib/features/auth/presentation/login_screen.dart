import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_asset_icon.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_modal_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../domain/auth_validators.dart';
import 'widgets/auth_background.dart';
import 'widgets/auth_divider.dart';
import 'widgets/auth_inline_action_prompt.dart';

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
  final Future<void> Function()? onGoogleLogin;
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
  bool _loginLoading = false;
  bool _googleLoading = false;

  bool get _busy => widget.isLoading || _loginLoading || _googleLoading;

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

    setState(() => _loginLoading = true);
    try {
      await callback(_emailController.text.trim(), _passwordController.text);
    } finally {
      if (mounted) setState(() => _loginLoading = false);
    }
  }

  Future<void> _submitGoogle() async {
    if (_busy) return;
    final callback = widget.onGoogleLogin;
    if (callback == null) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _googleLoading = true);

    try {
      await callback();
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        Scaffold(
          resizeToAvoidBottomInset: true,
      body: AuthBackground(
        child: SafeArea(
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
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
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
                                          aspectRatio: 1,
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
                                  enabled: !_busy,
                                  autofillHints: const [AutofillHints.email],
                                  validator: AuthValidators.email,
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
                                  enabled: !_busy,
                                  autofillHints: const [AutofillHints.password],
                                  validator: AuthValidators.password,
                                  onFieldSubmitted: (_) => _submit(),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    key: const ValueKey('forgot-password'),
                                    onPressed: _busy
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
                                const AuthDivider(),
                                const SizedBox(height: AppSpacing.lg),
                                AppButton.outlined(
                                  key: const ValueKey('google-login-button'),
                                  label: 'Continue with Google',
                                  onPressed: _busy ? null : _submitGoogle,
                                  isLoading: _googleLoading,
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
                                  onPressed: _busy
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
                                  isEnabled: !_busy,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                AuthInlineActionPrompt(
                                  message: "Don't have an account? ",
                                  actionLabel: 'Sign Up',
                                  enabled: !_busy,
                                  actionKey: const ValueKey('sign-up-link'),
                                  onAction: widget.onSignUp,
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
        ),
        if (_busy)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ModalBarrier(
                    dismissible: false,
                    color: AppColors.confirmationBackdrop,
                  ),
                  SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.pageHorizontal,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: const AppModalCard(
                            semanticLabel: 'Loading',
                            child: Center(
                              widthFactor: 1,
                              heightFactor: 1,
                              child: AppLoader(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
