import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_surface_container.dart';

class NotificationSettingsPreferences {
  const NotificationSettingsPreferences({
    this.newGamesNearby = true,
    this.gameInvitations = true,
    this.playersJoiningMyGame = true,
    this.gameConfirmations = true,
    this.gameReminders = true,
    this.scheduleChanges = true,
    this.newMessages = true,
    this.subscriptionUpdates = true,
  });

  final bool newGamesNearby;
  final bool gameInvitations;
  final bool playersJoiningMyGame;
  final bool gameConfirmations;
  final bool gameReminders;
  final bool scheduleChanges;
  final bool newMessages;
  final bool subscriptionUpdates;

  NotificationSettingsPreferences copyWith({
    bool? newGamesNearby,
    bool? gameInvitations,
    bool? playersJoiningMyGame,
    bool? gameConfirmations,
    bool? gameReminders,
    bool? scheduleChanges,
    bool? newMessages,
    bool? subscriptionUpdates,
  }) {
    return NotificationSettingsPreferences(
      newGamesNearby: newGamesNearby ?? this.newGamesNearby,
      gameInvitations: gameInvitations ?? this.gameInvitations,
      playersJoiningMyGame: playersJoiningMyGame ?? this.playersJoiningMyGame,
      gameConfirmations: gameConfirmations ?? this.gameConfirmations,
      gameReminders: gameReminders ?? this.gameReminders,
      scheduleChanges: scheduleChanges ?? this.scheduleChanges,
      newMessages: newMessages ?? this.newMessages,
      subscriptionUpdates: subscriptionUpdates ?? this.subscriptionUpdates,
    );
  }
}

typedef NotificationSettingsSaveCallback = Future<bool> Function(
  NotificationSettingsPreferences preferences,
);

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({
    super.key,
    this.onBack,
    this.initialPreferences = const NotificationSettingsPreferences(),
    this.onSave,
  });

  final VoidCallback? onBack;
  final NotificationSettingsPreferences initialPreferences;
  final NotificationSettingsSaveCallback? onSave;

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late NotificationSettingsPreferences _preferences;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _preferences = widget.initialPreferences;
  }

  @override
  void didUpdateWidget(covariant NotificationSettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPreferences != widget.initialPreferences) {
      _preferences = widget.initialPreferences;
    }
  }

  void _showUnavailable() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Notification settings are not connected yet.'),
        ),
      );
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    final callback = widget.onSave;
    if (callback == null) {
      _showUnavailable();
      return;
    }

    setState(() => _isSaving = true);
    try {
      await callback(_preferences);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _update(NotificationSettingsPreferences value) {
    setState(() => _preferences = value);
  }

  @override
  Widget build(BuildContext context) {
    final rows = <_NotificationSettingData>[
      _NotificationSettingData(
        id: 'new-games-nearby',
        label: 'New games nearby',
        value: _preferences.newGamesNearby,
        onChanged: (value) =>
            _update(_preferences.copyWith(newGamesNearby: value)),
      ),
      _NotificationSettingData(
        id: 'game-invitations',
        label: 'Game invitations',
        value: _preferences.gameInvitations,
        onChanged: (value) =>
            _update(_preferences.copyWith(gameInvitations: value)),
      ),
      _NotificationSettingData(
        id: 'players-joining-my-game',
        label: 'Players joining my game',
        value: _preferences.playersJoiningMyGame,
        onChanged: (value) =>
            _update(_preferences.copyWith(playersJoiningMyGame: value)),
      ),
      _NotificationSettingData(
        id: 'game-confirmations',
        label: 'Game confirmations',
        value: _preferences.gameConfirmations,
        onChanged: (value) =>
            _update(_preferences.copyWith(gameConfirmations: value)),
      ),
      _NotificationSettingData(
        id: 'game-reminders',
        label: 'Game reminders',
        value: _preferences.gameReminders,
        onChanged: (value) =>
            _update(_preferences.copyWith(gameReminders: value)),
      ),
      _NotificationSettingData(
        id: 'schedule-changes',
        label: 'Schedule changes',
        value: _preferences.scheduleChanges,
        onChanged: (value) =>
            _update(_preferences.copyWith(scheduleChanges: value)),
      ),
      _NotificationSettingData(
        id: 'new-messages',
        label: 'New messages',
        value: _preferences.newMessages,
        onChanged: (value) =>
            _update(_preferences.copyWith(newMessages: value)),
      ),
      _NotificationSettingData(
        id: 'subscription-updates',
        label: 'Subscription updates',
        value: _preferences.subscriptionUpdates,
        onChanged: (value) =>
            _update(_preferences.copyWith(subscriptionUpdates: value)),
      ),
    ];

    return Scaffold(
      key: const ValueKey('notification-settings-screen'),
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
                onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('notification-settings-scroll-view'),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal,
                  25,
                  AppSpacing.pageHorizontal,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSurfaceContainer(
                      key: const ValueKey('notification-settings-container'),
                      minHeight: 0,
                      padding: EdgeInsets.zero,
                      backgroundColor: AppColors.background,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var index = 0; index < rows.length; index++) ...[
                            _NotificationSettingRow(data: rows[index]),
                            if (index < rows.length - 1)
                              const Divider(
                                height: 1,
                                color: AppColors.divider,
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton.primary(
                      key: const ValueKey('notification-settings-save'),
                      label: 'Save Settings',
                      onPressed: _handleSave,
                      isLoading: _isSaving,
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

class _NotificationSettingData {
  const _NotificationSettingData({
    required this.id,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String id;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
}

class _NotificationSettingRow extends StatelessWidget {
  const _NotificationSettingRow({required this.data});

  final _NotificationSettingData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              data.label,
              style: AppTypography.body16.copyWith(
                color: AppColors.heading,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _NotificationToggle(
            key: ValueKey('notification-setting-${data.id}'),
            value: data.value,
            semanticsLabel: data.label,
            onChanged: data.onChanged,
          ),
        ],
      ),
    );
  }
}

class _NotificationToggle extends StatelessWidget {
  const _NotificationToggle({
    required this.value,
    required this.onChanged,
    required this.semanticsLabel,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: value,
      label: semanticsLabel,
      child: InkResponse(
        onTap: () => onChanged(!value),
        radius: 24,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              width: 22,
              height: 12,
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: value
                    ? AppColors.primary
                    : AppColors.textSecondary.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(999),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: const SizedBox.square(
                  dimension: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
