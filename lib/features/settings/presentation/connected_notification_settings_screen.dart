import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_loader.dart';
import '../../notifications/data/notification_repository.dart';
import '../../notifications/domain/notification_preferences.dart';
import 'notification_settings_screen.dart';

class ConnectedNotificationSettingsScreen extends StatefulWidget {
  const ConnectedNotificationSettingsScreen({
    required this.repository,
    super.key,
    this.onBack,
  });

  final NotificationRepository repository;
  final VoidCallback? onBack;

  @override
  State<ConnectedNotificationSettingsScreen> createState() =>
      _ConnectedNotificationSettingsScreenState();
}

class _ConnectedNotificationSettingsScreenState
    extends State<ConnectedNotificationSettingsScreen> {
  NotificationPreferences? _preferences;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _errorMessage = null);

    try {
      final preferences = await widget.repository.loadSettings();
      if (!mounted) return;
      setState(() => _preferences = preferences);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _messageFor(error));
    }
  }

  Future<bool> _save(NotificationPreferences preferences) async {
    try {
      final saved = await widget.repository.saveSettings(preferences);
      if (!mounted) return true;
      setState(() => _preferences = saved);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Notification settings saved.')),
        );
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(_messageFor(error))));
      }
      return false;
    }
  }

  String _messageFor(Object error) {
    if (error is ApiException) return error.message;
    return 'Could not load notification settings. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final preferences = _preferences;
    if (preferences != null) {
      return NotificationSettingsScreen(
        initialPreferences: preferences,
        onBack: widget.onBack,
        onSave: _save,
      );
    }

    return Scaffold(
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
                title: 'Notification Settings',
                onBack:
                    widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: Center(
                child: _errorMessage == null
                    ? const AppLoader()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.pageHorizontal,
                            ),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: AppTypography.body14,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton(
                            onPressed: _load,
                            child: Text(
                              'Retry',
                              style: AppTypography.action14,
                            ),
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
