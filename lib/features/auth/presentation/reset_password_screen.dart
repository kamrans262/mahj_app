import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../domain/auth_validators.dart';
import 'widgets/auth_background.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    this.onBack,
    this.onResetPassword,
  });

  final VoidCallback? onBack;
  final Future<bool> Function(String password)? onResetPassword;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmationFocus = FocusNode();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    _passwordFocus.dispose();
    _confirmationFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final callback = widget.onResetPassword;
    if (callback == null) return;

    setState(() => _isSubmitting = true);
    try {
      await callback(_passwordController.text);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('reset-password-screen'),
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      body: AuthBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                      maxWidth: 480,
                    ),
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
                                key: const ValueKey('reset-password-back'),
                                onPressed:
                                    _isSubmitting ? null : widget.onBack,
                              ),
                            ),
                            const SizedBox(height: 54),
                            const Text(
                              'Create New Password',
                              key: ValueKey('reset-password-heading'),
                              textAlign: TextAlign.center,
                              style: AppTypography.authHeading,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Choose a new password for your Mahj account.',
                              textAlign: TextAlign.center,
                              style: AppTypography.loginSubtitle.copyWith(
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            AppTextField(
                              key: const ValueKey('reset-new-password'),
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              hintText: 'New Password',
                              leadingIcon: Icons.lock_outline_rounded,
                              obscureText: true,
                              enabled: !_isSubmitting,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.newPassword,
                              ],
                              validator: AuthValidators.newPassword,
                              onFieldSubmitted: (_) {
                                _confirmationFocus.requestFocus();
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AppTextField(
                              key: const ValueKey(
                                'reset-confirm-password',
                              ),
                              controller: _confirmationController,
                              focusNode: _confirmationFocus,
                              hintText: 'Confirm Password',
                              leadingIcon: Icons.lock_outline_rounded,
                              obscureText: true,
                              enabled: !_isSubmitting,
                              textInputAction: TextInputAction.done,
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
                            const SizedBox(height: 44),
                            AppButton.primary(
                              key: const ValueKey(
                                'reset-password-submit',
                              ),
                              label: 'Reset Password',
                              onPressed: _submit,
                              isLoading: _isSubmitting,
                              isEnabled: !_isSubmitting,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
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
