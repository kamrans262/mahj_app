import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_asset_icon.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../core/widgets/app_surface_container.dart';
import '../../../core/widgets/app_text_field.dart';

typedef AccountEmailChangeCallback = Future<bool> Function(String email);
typedef AccountPasswordChangeCallback = Future<bool> Function(
  String newPassword,
  String confirmPassword,
);
typedef AccountDeleteCallback = Future<bool> Function();

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({
    super.key,
    this.onBack,
    this.initialEmail = '',
    this.isGoogleConnected = false,
    this.isAppleConnected = false,
    this.onChangeEmail,
    this.onChangePassword,
    this.onDeleteAccount,
  });

  final VoidCallback? onBack;
  final String initialEmail;
  final bool isGoogleConnected;
  final bool isAppleConnected;
  final AccountEmailChangeCallback? onChangeEmail;
  final AccountPasswordChangeCallback? onChangePassword;
  final AccountDeleteCallback? onDeleteAccount;

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  late final TextEditingController _emailController;
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _changingEmail = false;
  bool _changingPassword = false;
  bool _deleteDialogOpen = false;
  bool _deleteRequestInFlight = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showUnavailable(String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label is not connected yet.')));
  }

  Future<void> _handleChangeEmail() async {
    if (_changingEmail) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final callback = widget.onChangeEmail;
    if (callback == null) {
      _showUnavailable('Change email');
      return;
    }

    setState(() => _changingEmail = true);
    try {
      await callback(_emailController.text.trim());
    } finally {
      if (mounted) setState(() => _changingEmail = false);
    }
  }

  Future<void> _handleChangePassword() async {
    if (_changingPassword) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final callback = widget.onChangePassword;
    if (callback == null) {
      _showUnavailable('Change password');
      return;
    }

    setState(() => _changingPassword = true);
    try {
      await callback(
        _newPasswordController.text,
        _confirmPasswordController.text,
      );
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  Future<bool> _submitDelete() async {
    if (_deleteRequestInFlight) return false;
    final callback = widget.onDeleteAccount;
    if (callback == null) return false;

    _deleteRequestInFlight = true;
    try {
      return await callback();
    } finally {
      _deleteRequestInFlight = false;
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    if (_deleteDialogOpen) return;
    _deleteDialogOpen = true;
    var unavailableDeleteAttempted = false;

    try {
      final deleted = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Delete account',
        barrierColor: AppColors.confirmationBackdrop,
        transitionDuration: const Duration(milliseconds: 160),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          var isLoading = false;
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final navigator = Navigator.of(dialogContext);

              Future<void> confirmDelete() async {
                if (isLoading) return;
                if (widget.onDeleteAccount == null) {
                  unavailableDeleteAttempted = true;
                  navigator.pop(false);
                  return;
                }

                setDialogState(() => isLoading = true);
                final didDelete = await _submitDelete();
                if (!navigator.mounted) return;

                if (didDelete) {
                  navigator.pop(true);
                } else {
                  setDialogState(() => isLoading = false);
                }
              }

              return PopScope(
                canPop: !isLoading,
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pageHorizontal,
                        vertical: AppSpacing.lg,
                      ),
                      child: AppConfirmationDialog(
                        title: 'Delete Account?',
                        message: 'Are you sure you want to delete your account?\nThis action cannot be undone.',
                        cancelLabel: 'Cancel',
                        confirmLabel: 'Delete',
                        isLoading: isLoading,
                        confirmVariant: AppConfirmationVariant.destructive,
                        onCancel: isLoading ? null : () => navigator.pop(false),
                        onConfirm: isLoading ? null : confirmDelete,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      );

      if (!mounted || deleted == true) return;
      if (unavailableDeleteAttempted) {
        _showUnavailable('Account deletion');
      }
    } finally {
      _deleteDialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('account-settings-screen'),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.lg,
                AppSpacing.pageHorizontal,
                0,
              ),
              child: AppCenteredPageHeader(
                title: 'Account Settings',
                onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('account-settings-scroll-view'),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal,
                  25,
                  AppSpacing.pageHorizontal,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionLabel('Change Email'),
                    const SizedBox(height: AppSpacing.xs),
                    AppTextField(
                      key: const ValueKey('account-settings-email'),
                      controller: _emailController,
                      hintText: 'Email Address',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton.primary(
                      key: const ValueKey('account-settings-change-email'),
                      label: 'Change Email',
                      onPressed: _handleChangeEmail,
                      isLoading: _changingEmail,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionLabel('Change Password'),
                    const SizedBox(height: AppSpacing.xs),
                    AppTextField(
                      key: const ValueKey('account-settings-new-password'),
                      controller: _newPasswordController,
                      hintText: 'New Password',
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppTextField(
                      key: const ValueKey('account-settings-confirm-password'),
                      controller: _confirmPasswordController,
                      hintText: 'Confirm Password',
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton.primary(
                      key: const ValueKey('account-settings-change-password'),
                      label: 'Change Password',
                      onPressed: _handleChangePassword,
                      isLoading: _changingPassword,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionLabel('Connected Accounts'),
                    const SizedBox(height: AppSpacing.xs),
                    AppSurfaceContainer(
                      key: const ValueKey('account-settings-connected'),
                      minHeight: 0,
                      padding: EdgeInsets.zero,
                      backgroundColor: AppColors.background,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ConnectedAccountRow(
                            iconAsset: AppAssets.googleLoginIcon,
                            label: 'Google',
                            isConnected: widget.isGoogleConnected,
                          ),
                          const Divider(height: 1, color: AppColors.divider),
                          _ConnectedAccountRow(
                            iconAsset: AppAssets.appleLoginIcon,
                            label: 'Apple',
                            isConnected: widget.isAppleConnected,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionLabel('Delete Account'),
                    const SizedBox(height: AppSpacing.xs),
                    AppButton.destructiveOutlined(
                      key: const ValueKey('account-settings-delete'),
                      label: 'Delete Account',
                      onPressed: _showDeleteAccountDialog,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.homeMeta14);
  }
}

class _ConnectedAccountRow extends StatelessWidget {
  const _ConnectedAccountRow({
    required this.iconAsset,
    required this.label,
    required this.isConnected,
  });

  final String iconAsset;
  final String label;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          AppAssetIcon(assetPath: iconAsset, size: 18),
          const SizedBox(width: AppSpacing.micro),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body16.copyWith(
                color: AppColors.heading,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            isConnected ? 'Connected' : 'Not connected',
            style: AppTypography.homeMeta12.copyWith(
              color: isConnected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
