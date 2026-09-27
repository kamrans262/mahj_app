import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../data/filter_location_options.dart';
import '../../domain/match_filters.dart';
import 'compact_switch.dart';

class HomeFilterSheet extends StatefulWidget {
  const HomeFilterSheet({
    required this.initialFilters,
    required this.onApply,
    required this.onClose,
    super.key,
  });

  final MatchFilters initialFilters;
  final Future<void> Function(MatchFilters filters) onApply;
  final VoidCallback onClose;

  @override
  State<HomeFilterSheet> createState() => _HomeFilterSheetState();
}

class _HomeFilterSheetState extends State<HomeFilterSheet> {
  late MatchFilters _draft;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialFilters;
  }

  @override
  void didUpdateWidget(covariant HomeFilterSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilters != widget.initialFilters && !_applying) {
      _draft = widget.initialFilters;
    }
  }

  Future<void> _selectLocation() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          title: Text(
            'Select Location',
            style: AppTypography.homeMatchTitle18,
          ),
          contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: FilterLocationOptions.values.map((location) {
                  final selected = location == _draft.selectedLocation;
                  return ListTile(
                    onTap: () => Navigator.of(context).pop(location),
                    title: Text(
                      location,
                      style: AppTypography.homeMeta14.copyWith(
                        color: AppColors.heading,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          )
                        : null,
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) return;

    setState(() {
      _draft = _draft.copyWith(selectedLocation: selected);
    });
  }

  void _reset() {
    setState(() {
      _draft = MatchFilters.defaults();
    });
  }

  Future<void> _apply() async {
    if (_applying) return;

    setState(() => _applying = true);
    try {
      await widget.onApply(_draft);
    } finally {
      if (mounted) {
        setState(() => _applying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return Material(
      color: AppColors.background,
      elevation: 12,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = constraints.maxHeight * 0.92;

          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                20,
                AppSpacing.pageHorizontal,
                20,
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
                  Text(
                    'Select Radius',
                    style: AppTypography.homeMatchTitle18,
                  ),
                  const SizedBox(height: 12),
                  _LocationFilterField(
                    selectedLocation: _draft.selectedLocation,
                    onTap: _selectLocation,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _RadiusSlider(
                    value: _draft.radiusMiles,
                    onChanged: (value) {
                      setState(() {
                        _draft = _draft.copyWith(radiusMiles: value);
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FilterRow(
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
                  const SizedBox(height: AppSpacing.lg),
                  _FilterRow(
                    label: 'Sort by Distance',
                    trailing: _SelectedRadio(
                      selected:
                          _draft.sortOption == MatchSortOption.distance,
                    ),
                    onTap: () {
                      setState(() {
                        _draft = _draft.copyWith(
                          sortOption: MatchSortOption.distance,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 30),
                  _ActionButtons(
                    textScale: textScale,
                    applying: _applying,
                    onReset: _reset,
                    onApply: _apply,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LocationFilterField extends StatelessWidget {
  const _LocationFilterField({
    required this.selectedLocation,
    required this.onTap,
  });

  final String selectedLocation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = selectedLocation == MatchFilters.defaultLocation
        ? 'Select by Location'
        : selectedLocation;

    return Semantics(
      button: true,
      label: 'Filter location: $label',
      child: Material(
        color: AppColors.nearbyMatchCardSurface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.65),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 24,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.homeMeta14,
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

class _RadiusSlider extends StatelessWidget {
  const _RadiusSlider({
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Search radius',
      value: '${value.round()} miles',
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.filterSliderInactive,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.10),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 7,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 16,
              ),
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
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1 mile',
                style: AppTypography.homeMeta14,
              ),
              Text(
                '10 miles',
                style: AppTypography.homeMeta14,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
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
        borderRadius: BorderRadius.circular(10),
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

class _SelectedRadio extends StatelessWidget {
  const _SelectedRadio({required this.selected});

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
              color: selected
                  ? AppColors.primary
                  : AppColors.textSecondary,
              width: 1.5,
            ),
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: selected ? 10 : 0,
              height: selected ? 10 : 0,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.textScale,
    required this.applying,
    required this.onReset,
    required this.onApply,
  });

  final double textScale;
  final bool applying;
  final VoidCallback onReset;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final stackButtons = textScale > 1.35;

    final reset = SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: applying ? null : onReset,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        child: const Text('Reset Filters'),
      ),
    );

    final apply = SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: applying ? null : onApply,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        child: applying
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Apply Filters'),
      ),
    );

    if (stackButtons) {
      return Column(
        children: [
          reset,
          const SizedBox(height: 10),
          apply,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: reset),
        const SizedBox(width: 10),
        Expanded(child: apply),
      ],
    );
  }
}
