import 'dart:async';

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
  Timer? _searchDebounce;
  List<DiscoveryLocation> _results = const [];
  bool _searching = false;
  bool _findingCurrentLocation = false;
  int _searchRequest = 0;
  String? _error;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();

    if (query.length < 2) {
      setState(() {
        _results = const [];
        _error = null;
        _searching = false;
      });
      return;
    }

    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(_search(query)),
    );
  }

  Future<void> _search([String? submittedQuery]) async {
    final query = (submittedQuery ?? _controller.text).trim();
    if (query.length < 2) {
      setState(
        () => _error =
            'Enter an area, address, venue, city or ZIP code.',
      );
      return;
    }

    final request = ++_searchRequest;
    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final results = await widget.onSearch(query);
      if (!mounted ||
          request != _searchRequest ||
          _controller.text.trim() != query) {
        return;
      }

      setState(() {
        _results = results;
        _error = results.isEmpty ? 'No matching locations found.' : null;
      });
    } catch (error) {
      if (!mounted || request != _searchRequest) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted && request == _searchRequest) {
        setState(() => _searching = false);
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_findingCurrentLocation) return;

    setState(() {
      _findingCurrentLocation = true;
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
      if (mounted) setState(() => _findingCurrentLocation = false);
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
                hintText: 'Search area, address or venue',
                leadingIcon: Icons.search,
                textInputAction: TextInputAction.search,
                enabled: !_findingCurrentLocation,
                onChanged: _onSearchChanged,
                onFieldSubmitted: (value) {
                  _searchDebounce?.cancel();
                  unawaited(_search(value));
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: AppButton.secondary(
                  label: _findingCurrentLocation
                      ? 'Finding Location...'
                      : 'Use Current Location',
                  onPressed: _findingCurrentLocation
                      ? null
                      : _useCurrentLocation,
                  isEnabled: !_findingCurrentLocation,
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
              ] else if (!_searching) ...[
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: AppButton.primary(
                    label: 'Search',
                    onPressed: () => unawaited(_search()),
                  ),
                ),
              ],
              if (_searching) ...[
                const SizedBox(height: AppSpacing.sm),
                const LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
