import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import 'widgets/settings_section.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.onBack,
    this.onAccountSettingsTap,
    this.onNotificationSettingsTap,
    this.onLocationSettingsTap,
    this.onSubscriptionTap,
    this.onPrivacySafetyTap,
    this.onFaqTap,
    this.onSupportTap,
    this.onTermsTap,
    this.onPrivacyPolicyTap,
    this.onLogOut,
    this.onDeleteAccount,
  });

  final VoidCallback? onBack;
  final VoidCallback? onAccountSettingsTap;
  final VoidCallback? onNotificationSettingsTap;
  final VoidCallback? onLocationSettingsTap;
  final VoidCallback? onSubscriptionTap;
  final VoidCallback? onPrivacySafetyTap;
  final VoidCallback? onFaqTap;
  final VoidCallback? onSupportTap;
  final VoidCallback? onTermsTap;
  final VoidCallback? onPrivacyPolicyTap;
  final Future<bool> Function()? onLogOut;
  final Future<bool> Function()? onDeleteAccount;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _deleteDialogOpen = false;
  bool _deleteRequestInFlight = false;

  void _showUnavailable(String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label is not connected yet.')));
  }

  VoidCallback _actionOrFallback(VoidCallback? action, String label) {
    return action ?? () => _showUnavailable(label);
  }

  Future<void> _handleLogOut() async {
    final callback = widget.onLogOut;
    if (callback == null) {
      _showUnavailable('Log out');
      return;
    }

    final success = await callback();
    if (!mounted || success) return;
    _showUnavailable('Log out');
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
    final sections = <SettingsSection>[
      SettingsSection(
        label: 'Account',
        items: [
          SettingsItemData(
            id: 'account',
            title: 'Account Settings',
            iconAsset: AppAssets.settingsAccountIcon,
            trailingAsset: AppAssets.settingsForwardIcon,
            onTap: _actionOrFallback(
              widget.onAccountSettingsTap,
              'Account Settings',
            ),
          ),
        ],
      ),
      SettingsSection(
        label: 'Preferences',
        items: [
          SettingsItemData(
            id: 'notification',
            title: 'Notification',
            iconAsset: AppAssets.homeBellIcon,
            trailingAsset: AppAssets.settingsForwardIcon,
            onTap: _actionOrFallback(
              widget.onNotificationSettingsTap,
              'Notification Settings',
            ),
          ),
          SettingsItemData(
            id: 'location',
            title: 'Location',
            iconAsset: AppAssets.bottomMapIcon,
            trailingAsset: AppAssets.settingsForwardIcon,
            onTap: _actionOrFallback(
              widget.onLocationSettingsTap,
              'Location Settings',
            ),
          ),
          SettingsItemData(
            id: 'subscription',
            title: 'Subscription',
            iconAsset: AppAssets.premiumCrownIcon,
            trailingAsset: AppAssets.settingsForwardIcon,
            onTap: _actionOrFallback(widget.onSubscriptionTap, 'Subscription'),
          ),
        ],
      ),
      SettingsSection(
        label: 'Safety',
        items: [
          SettingsItemData(
            id: 'privacy-safety',
            title: 'Privacy and Safety',
            iconAsset: AppAssets.settingsShieldIcon,
            trailingAsset: AppAssets.settingsForwardIcon,
            onTap: _actionOrFallback(
              widget.onPrivacySafetyTap,
              'Privacy and Safety',
            ),
          ),
        ],
      ),
      SettingsSection(
        label: 'Help & Support',
        items: [
          SettingsItemData(
            id: 'faqs',
            title: 'FAQs',
            iconAsset: AppAssets.settingsHelpIcon,
            trailingAsset: AppAssets.settingsForwardIcon,
            onTap: _actionOrFallback(widget.onFaqTap, 'FAQs'),
          ),
          SettingsItemData(
            id: 'support',
            title: 'Support',
            iconAsset: AppAssets.settingsShieldIcon,
            trailingAsset: AppAssets.settingsForwardIcon,
            onTap: _actionOrFallback(widget.onSupportTap, 'Support'),
          ),
        ],
      ),
      SettingsSection(
        label: 'Legal',
        items: [
          SettingsItemData(
            id: 'terms',
            title: 'Terms & Conditions',
            iconAsset: AppAssets.settingsAccountIcon,
            trailingAsset: AppAssets.settingsForwardIcon,
            onTap: _actionOrFallback(widget.onTermsTap, 'Terms & Conditions'),
          ),
          SettingsItemData(
            id: 'privacy-policy',
            title: 'Privacy Policy',
            iconAsset: AppAssets.settingsShieldIcon,
            trailingAsset: AppAssets.settingsForwardIcon,
            onTap: _actionOrFallback(
              widget.onPrivacyPolicyTap,
              'Privacy Policy',
            ),
          ),
        ],
      ),
      SettingsSection(
        items: [
          SettingsItemData(
            id: 'logout',
            title: 'Log Out',
            iconAsset: AppAssets.settingsLogoutIcon,
            trailingAsset: AppAssets.settingsForwardIcon,
            onTap: _handleLogOut,
          ),
          SettingsItemData(
            id: 'delete-account',
            title: 'Delete Account',
            iconAsset: AppAssets.settingsDeleteIcon,
            trailingAsset: AppAssets.settingsForwardIcon,
            onTap: _showDeleteAccountDialog,
          ),
        ],
      ),
    ];

    return Scaffold(
      key: const ValueKey('settings-screen'),
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
                title: 'Settings',
                onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('settings-scroll-view'),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal,
                  25,
                  AppSpacing.pageHorizontal,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0; index < sections.length; index++) ...[
                      sections[index],
                      if (index < sections.length - 1)
                        const SizedBox(height: AppSpacing.lg),
                    ],
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
