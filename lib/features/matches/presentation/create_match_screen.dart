import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_surface_container.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../home/domain/home_match.dart';
import '../../home/presentation/widgets/compact_switch.dart';
import '../domain/create_match_form_state.dart';
import 'widgets/match_created_overlay.dart';

class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({
    super.key,
    this.onBack,
    this.onCancel,
    this.onSubmit,
    this.onInvitePlayers,
    this.onBackHome,
    this.onViewMatch,
  });

  final VoidCallback? onBack;
  final VoidCallback? onCancel;
  final Future<HomeMatch> Function(CreateMatchRequest request)? onSubmit;
  final ValueChanged<HomeMatch>? onInvitePlayers;
  final ValueChanged<HomeMatch>? onBackHome;
  final ValueChanged<HomeMatch>? onViewMatch;

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  static const double _headerToBodyGap = 35;

  final _locationController = TextEditingController();
  final _venueController = TextEditingController();

  CreateMatchFormState _formState = const CreateMatchFormState();
  bool _isSubmitting = false;
  HomeMatch? _createdMatch;

  @override
  void dispose() {
    _locationController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  void _goBack() {
    final callback = widget.onBack;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).maybePop();
  }

  void _cancel() {
    FocusManager.instance.primaryFocus?.unfocus();

    final callback = widget.onCancel;
    if (callback != null) {
      callback();
      return;
    }

    Navigator.of(context).maybePop();
  }

  Future<void> _selectDate() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final now = DateTime.now();
    final initialDate = _formState.selectedDate ?? now;

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2, 12, 31),
      helpText: 'Select match date',
    );

    if (!mounted || selected == null) return;

    setState(() {
      _formState = _formState.copyWith(selectedDate: selected);
    });
  }

  Future<void> _selectTime() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final minutes = _formState.selectedTimeMinutes;
    final initialTime = minutes == null
        ? TimeOfDay.now()
        : TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

    final selected = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'Select match time',
    );

    if (!mounted || selected == null) return;

    setState(() {
      _formState = _formState.copyWith(
        selectedTimeMinutes: selected.hour * 60 + selected.minute,
      );
    });
  }

  String _dateLabel() {
    final date = _formState.selectedDate;
    if (date == null) return 'Date';

    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  String _timeLabel() {
    final minutes = _formState.selectedTimeMinutes;
    if (minutes == null) return 'Time';

    final selectedTime = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

    return MaterialLocalizations.of(context).formatTimeOfDay(
      selectedTime,
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
  }

  String? _validationMessage() {
    final location = _formState.locationAddress;

    if (location == null || location.trim().isEmpty) {
      return 'Please enter a location or address.';
    }
    if (_formState.selectedDate == null) {
      return 'Please select a match date.';
    }
    if (_formState.selectedTimeMinutes == null) {
      return 'Please select a match time.';
    }

    return null;
  }

  Future<void> _submit() async {
    if (_isSubmitting || _createdMatch != null) return;

    FocusManager.instance.primaryFocus?.unfocus();

    final validationMessage = _validationMessage();
    if (validationMessage != null) {
      _showMessage(validationMessage);
      return;
    }

    final request = _formState.toRequest();
    if (request == null) {
      _showMessage('Please complete the required match details.');
      return;
    }

    final callback = widget.onSubmit;
    if (callback == null) {
      _showMessage('Match creation is not connected yet.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final createdMatch = await callback(request);
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _createdMatch = createdMatch;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _isSubmitting = false);
      _showMessage('Could not create the match. Please try again.');
    }
  }

  void _handleBackHome(HomeMatch match) {
    final callback = widget.onBackHome;
    if (callback != null) {
      callback(match);
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  void _handleInvitePlayers(HomeMatch match) {
    widget.onInvitePlayers?.call(match);
  }

  void _handleViewMatch(HomeMatch match) {
    widget.onViewMatch?.call(match);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildLocationField() {
    return AppTextField(
      controller: _locationController,
      hintText: 'Location/Address',
      leadingIcon: Icons.location_on_outlined,
      enabled: !_isSubmitting,
      keyboardType: TextInputType.streetAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.fullStreetAddress],
      onChanged: (value) {
        _formState = _formState.copyWith(locationAddress: value);
      },
    );
  }

  Widget _buildVenueField() {
    return AppTextField(
      controller: _venueController,
      hintText: 'Venue Name (Optional)',
      leadingIcon: Icons.apartment_outlined,
      enabled: !_isSubmitting,
      textInputAction: TextInputAction.done,
      onChanged: (value) {
        _formState = _formState.copyWith(venueName: value);
      },
      onFieldSubmitted: (_) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
    );
  }

  Widget _buildDateTimeFields() {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final shouldStack =
        textScale > 1.35 || MediaQuery.sizeOf(context).width < 340;

    final dateField = _PickerSurfaceField(
      label: _dateLabel(),
      semanticLabel: 'Select match date',
      leadingIcon: Icons.calendar_today_outlined,
      onTap: _isSubmitting ? null : _selectDate,
    );

    final timeField = _PickerSurfaceField(
      label: _timeLabel(),
      semanticLabel: 'Select match time',
      leadingIcon: Icons.access_time_rounded,
      onTap: _isSubmitting ? null : _selectTime,
    );

    if (shouldStack) {
      return Column(
        children: [
          dateField,
          const SizedBox(height: AppSpacing.lg),
          timeField,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: dateField),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: timeField),
      ],
    );
  }

  Widget _buildActionButtons() {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final shouldStack =
        textScale > 1.35 || MediaQuery.sizeOf(context).width < 340;

    final cancel = AppButton.secondary(
      label: 'Cancel',
      onPressed: _isSubmitting ? null : _cancel,
      isEnabled: !_isSubmitting,
    );

    final create = AppButton.primary(
      label: 'Create Match',
      onPressed: _isSubmitting ? null : _submit,
      isLoading: _isSubmitting,
    );

    if (shouldStack) {
      return Column(
        children: [
          cancel,
          const SizedBox(height: AppSpacing.sm),
          create,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: cancel),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: create),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final createdMatch = _createdMatch;

    return PopScope(
      canPop: createdMatch == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && createdMatch != null) {
          _handleBackHome(createdMatch);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Scaffold(
            resizeToAvoidBottomInset: true,
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
                      title: 'Create Match',
                      onBack: _isSubmitting ? null : _goBack,
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const verticalBodyPadding =
                            _headerToBodyGap + AppSpacing.lg;
                        final minContentHeight =
                            constraints.maxHeight > verticalBodyPadding
                            ? constraints.maxHeight - verticalBodyPadding
                            : 0.0;

                        return SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.pageHorizontal,
                            _headerToBodyGap,
                            AppSpacing.pageHorizontal,
                            AppSpacing.lg,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: minContentHeight,
                            ),
                            child: IntrinsicHeight(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildLocationField(),
                                  const SizedBox(height: AppSpacing.lg),
                                  _buildVenueField(),
                                  const SizedBox(height: AppSpacing.lg),
                                  _buildDateTimeFields(),
                                  const SizedBox(height: AppSpacing.lg),
                                  _ToggleFormRow(
                                    title: 'Public Match',
                                    subtitle: 'Anyone can find and join',
                                    value: _formState.isPublicMatch,
                                    enabled: !_isSubmitting,
                                    onChanged: (value) {
                                      setState(() {
                                        _formState = _formState.copyWith(
                                          isPublicMatch: value,
                                        );
                                      });
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  _ToggleFormRow(
                                    title: 'Invite Only (optional)',
                                    subtitle: 'Only those you invite can join',
                                    value: _formState.isInviteOnly,
                                    enabled: !_isSubmitting,
                                    onChanged: (value) {
                                      setState(() {
                                        _formState = _formState.copyWith(
                                          isInviteOnly: value,
                                        );
                                      });
                                    },
                                  ),
                                  const Spacer(),
                                  const SizedBox(height: AppSpacing.xl),
                                  _buildActionButtons(),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (createdMatch != null)
            MatchCreatedOverlay(
              match: createdMatch,
              onInvitePlayers: widget.onInvitePlayers == null
                  ? null
                  : _handleInvitePlayers,
              onBackHome: _handleBackHome,
              onViewMatch: widget.onViewMatch == null ? null : _handleViewMatch,
            ),
        ],
      ),
    );
  }
}

class _PickerSurfaceField extends StatelessWidget {
  const _PickerSurfaceField({
    required this.label,
    required this.semanticLabel,
    required this.leadingIcon,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final IconData leadingIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceContainer(
      onTap: onTap,
      semanticsLabel: semanticLabel,
      minHeight: 50,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(leadingIcon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.micro),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.homeMeta14,
            ),
          ),
          const SizedBox(width: AppSpacing.micro),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _ToggleFormRow extends StatelessWidget {
  const _ToggleFormRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: value,
      enabled: enabled,
      label: title,
      value: value ? 'On' : 'Off',
      child: Material(
        color: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: InkWell(
          onTap: enabled ? () => onChanged(!value) : null,
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: AppTypography.homeMatchTitle18.copyWith(
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.micro),
                      Text(
                        subtitle,
                        style: AppTypography.homeMeta12.copyWith(
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ExcludeSemantics(
                  child: IgnorePointer(
                    child: CompactSwitch(value: value, onChanged: null),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
