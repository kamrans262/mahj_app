import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_surface_container.dart';
import '../../domain/discovery_location.dart';
import '../../domain/match_filters.dart';
import 'compact_switch.dart';
import 'location_selection_dialog.dart';

class HomeFilterSheet extends StatefulWidget {
  const HomeFilterSheet({
    required this.initialFilters,
    required this.onApply,
    required this.onLocationSearch,
    required this.onCurrentLocation,
    super.key,
  });

  final MatchFilters initialFilters;
  final Future<void> Function(MatchFilters filters) onApply;
  final Future<List<DiscoveryLocation>> Function(String query) onLocationSearch;
  final Future<DiscoveryLocation> Function() onCurrentLocation;

  @override
  State<HomeFilterSheet> createState() => _HomeFilterSheetState();
}

class _HomeFilterSheetState extends State<HomeFilterSheet> {
  late MatchFilters _draft;
  bool _isApplying = false;
  String? _applyError;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialFilters;
  }

  Future<void> _selectLocation() async {
    final selected = await showLocationSelectionDialog(
      context: context,
      selectedLocation: _draft.selectedLocation,
      onSearch: widget.onLocationSearch,
      onCurrentLocation: widget.onCurrentLocation,
    );

    if (!mounted || selected == null) return;

    setState(() {
      _applyError = null;
      _draft = _draft.copyWith(
        selectedLocation: selected.label,
        latitude: selected.latitude,
        longitude: selected.longitude,
      );
    });
  }

  void _reset() {
    setState(() {
      _applyError = null;
      _draft = MatchFilters.defaults();
    });
  }

  Future<void> _apply() async {
    if (_isApplying) return;

    setState(() {
      _isApplying = true;
      _applyError = null;
    });
    try {
      var filters = _draft;
      if (filters.usesCurrentLocation && !filters.hasCoordinates) {
        final current = await widget.onCurrentLocation();
        filters = filters.copyWith(
          selectedLocation: current.label,
          latitude: current.latitude,
          longitude: current.longitude,
        );
      }

      if (!mounted) return;
      _draft = filters;
      await widget.onApply(filters);
    } catch (error) {
      if (mounted) {
        setState(() => _applyError = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final bottomInset = mediaQuery.padding.bottom;

    return Material(
      color: AppColors.background,
      elevation: 12,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheetTop),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.72),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            20,
            AppSpacing.pageHorizontal,
            20 + bottomInset,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filters',
                textAlign: TextAlign.center,
                style: AppTypography.homeGreeting,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Select Radius', style: AppTypography.homeMatchTitle18),
              const SizedBox(height: 12),
              _LocationField(
                selectedLocation: _draft.selectedLocation,
                onTap: _selectLocation,
              ),
              const SizedBox(height: AppSpacing.lg),
              _RadiusControl(
                value: _draft.radiusMiles,
                onChanged: (value) {
                  setState(() {
                    _draft = _draft.copyWith(radiusMiles: value);
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Date', style: AppTypography.homeMatchTitle18),
              const SizedBox(height: 12),
              _DateFilterField(
                value: _draft.dateFilter,
                onChanged: (value) {
                  setState(() => _draft = _draft.copyWith(dateFilter: value));
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              _FilterOptionRow(
                label: 'Show Open Matches Only',
                trailing: CompactSwitch(
                  value: _draft.showOpenOnly,
                  semanticsLabel: 'Show open matches only',
                  onChanged: (value) {
                    setState(() {
                      _draft = _draft.copyWith(showOpenOnly: value);
                    });
                  },
                ),
                onTap: () {
                  setState(() {
                    _draft = _draft.copyWith(
                      showOpenOnly: !_draft.showOpenOnly,
                    );
                  });
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _FilterOptionRow(
                label: 'Sort by Distance',
                trailing: _FilterRadio(
                  selected: _draft.sortOption == MatchSortOption.distance,
                ),
                onTap: () {
                  setState(() {
                    _draft = _draft.copyWith(
                      sortOption: MatchSortOption.distance,
                    );
                  });
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _FilterOptionRow(
                label: 'Sort by Date',
                trailing: _FilterRadio(
                  selected: _draft.sortOption == MatchSortOption.date,
                ),
                onTap: () {
                  setState(() {
                    _draft = _draft.copyWith(sortOption: MatchSortOption.date);
                  });
                },
              ),
              if (_applyError != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _applyError!,
                  textAlign: TextAlign.center,
                  style: AppTypography.homeMeta12.copyWith(
                    color: AppColors.destructive,
                  ),
                ),
              ],
              const SizedBox(height: 30),
              _FilterActions(
                textScale: textScale,
                isApplying: _isApplying,
                onReset: _reset,
                onApply: _apply,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({required this.selectedLocation, required this.onTap});

  final String selectedLocation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayText = selectedLocation == MatchFilters.defaultLocation
        ? 'Current Location'
        : selectedLocation;

    return AppSurfaceContainer(
      onTap: onTap,
      semanticsLabel: 'Select filter location',
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 24,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.homeMeta14,
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _DateFilterField extends StatelessWidget {
  const _DateFilterField({required this.value, required this.onChanged});

  final MatchDateFilter value;
  final ValueChanged<MatchDateFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceContainer(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<MatchDateFilter>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: AppColors.textSecondary,
          ),
          items: MatchDateFilter.values
              .map(
                (filter) => DropdownMenuItem(
                  value: filter,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Text(filter.label, style: AppTypography.homeMeta14),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: (filter) {
            if (filter != null) onChanged(filter);
          },
        ),
      ),
    );
  }
}

class _RadiusControl extends StatelessWidget {
  const _RadiusControl({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Search radius',
      value: '${value.round()} miles',
      child: Column(
        children: [
          SizedBox(
            height: 28,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.filterSliderInactive,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withValues(alpha: 0.08),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                min: MatchFilters.minRadiusMiles,
                max: MatchFilters.maxRadiusMiles,
                divisions: 9,
                value: value.clamp(
                  MatchFilters.minRadiusMiles,
                  MatchFilters.maxRadiusMiles,
                ),
                onChanged: onChanged,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 mile', style: AppTypography.homeMeta14),
              Text('10 miles', style: AppTypography.homeMeta14),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterOptionRow extends StatelessWidget {
  const _FilterOptionRow({
    required this.label,
    required this.trailing,
    required this.onTap,
  });

  final String label;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.homeMatchTitle16.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterRadio extends StatelessWidget {
  const _FilterRadio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 44,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.textSecondary,
              width: 1.5,
            ),
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: selected ? 10 : 0,
              height: selected ? 10 : 0,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterActions extends StatelessWidget {
  const _FilterActions({
    required this.textScale,
    required this.isApplying,
    required this.onReset,
    required this.onApply,
  });

  final double textScale;
  final bool isApplying;
  final VoidCallback onReset;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final stackVertically =
        textScale > 1.35 || MediaQuery.sizeOf(context).width < 340;

    final resetButton = AppButton.secondary(
      label: 'Reset Filters',
      onPressed: isApplying ? null : onReset,
      isEnabled: !isApplying,
    );

    final applyButton = AppButton.primary(
      label: 'Apply Filters',
      onPressed: isApplying ? null : onApply,
      isLoading: isApplying,
    );

    if (stackVertically) {
      return Column(
        children: [resetButton, const SizedBox(height: 10), applyButton],
      );
    }

    return Row(
      children: [
        Expanded(child: resetButton),
        const SizedBox(width: 10),
        Expanded(child: applyButton),
      ],
    );
  }
}
