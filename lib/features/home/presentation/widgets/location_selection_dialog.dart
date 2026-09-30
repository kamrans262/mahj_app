import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/discovery_location.dart';

Future<DiscoveryLocation?> showLocationSelectionDialog({
  required BuildContext context,
  required String selectedLocation,
  required Future<List<DiscoveryLocation>> Function(String query) onSearch,
  required Future<DiscoveryLocation> Function() onCurrentLocation,
}) {
  return showDialog<DiscoveryLocation>(
    context: context,
    builder: (dialogContext) => _LocationSelectionDialog(
      selectedLocation: selectedLocation,
      onSearch: onSearch,
      onCurrentLocation: onCurrentLocation,
    ),
  );
}

class _LocationSelectionDialog extends StatefulWidget {
  const _LocationSelectionDialog({
    required this.selectedLocation,
    required this.onSearch,
    required this.onCurrentLocation,
  });

  final String selectedLocation;
  final Future<List<DiscoveryLocation>> Function(String query) onSearch;
  final Future<DiscoveryLocation> Function() onCurrentLocation;

  @override
  State<_LocationSelectionDialog> createState() =>
      _LocationSelectionDialogState();
}

class _LocationSelectionDialogState extends State<_LocationSelectionDialog> {
  final _controller = TextEditingController();
  List<DiscoveryLocation> _results = const [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.length < 2 || _loading) {
      if (query.length < 2) {
        setState(() => _error = 'Enter a city or ZIP code.');
      }
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await widget.onSearch(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        if (results.isEmpty) {
          _error = 'No matching locations found.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final location = await widget.onCurrentLocation();
      if (!mounted) return;
      Navigator.of(context).pop(location);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _select(DiscoveryLocation location) {
    Navigator.of(context).pop(location);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      title: Text('Select Location', style: AppTypography.homeMatchTitle18),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      content: SizedBox(
        width: 420,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 430),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: _controller,
                hintText: 'Enter city or ZIP code',
                leadingIcon: Icons.search,
                textInputAction: TextInputAction.search,
                enabled: !_loading,
                onFieldSubmitted: (_) => _search(),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: AppButton.secondary(
                  label: _loading
                      ? 'Finding Location...'
                      : 'Use Current Location',
                  onPressed: _loading ? null : _useCurrentLocation,
                  isEnabled: !_loading,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppTypography.homeMeta12.copyWith(
                    color: AppColors.destructive,
                  ),
                ),
              ],
              if (_results.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final location = _results[index];
                      final selected =
                          location.label == widget.selectedLocation;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        onTap: () => _select(location),
                        leading: const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          location.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.homeMeta14.copyWith(
                            color: AppColors.heading,
                          ),
                        ),
                        trailing: selected
                            ? const Icon(
                                Icons.check_circle,
                                size: 20,
                                color: AppColors.primary,
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ] else if (!_loading) ...[
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: AppButton.primary(
                    label: 'Search',
                    onPressed: _search,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
