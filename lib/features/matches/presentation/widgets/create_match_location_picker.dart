import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;

import '../../../../app/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_surface_container.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../home/domain/discovery_location.dart';

Future<DiscoveryLocation?> showCreateMatchLocationPicker({
  required BuildContext context,
  required Future<List<DiscoveryLocation>> Function(String query) onSearch,
  required Future<DiscoveryLocation> Function() onCurrentLocation,
  DiscoveryLocation? initialLocation,
}) {
  return showModalBottomSheet<DiscoveryLocation>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (sheetContext) => _CreateMatchLocationPicker(
      initialLocation: initialLocation,
      onSearch: onSearch,
      onCurrentLocation: onCurrentLocation,
    ),
  );
}

class _CreateMatchLocationPicker extends StatefulWidget {
  const _CreateMatchLocationPicker({
    required this.onSearch,
    required this.onCurrentLocation,
    this.initialLocation,
  });

  final DiscoveryLocation? initialLocation;
  final Future<List<DiscoveryLocation>> Function(String query) onSearch;
  final Future<DiscoveryLocation> Function() onCurrentLocation;

  @override
  State<_CreateMatchLocationPicker> createState() =>
      _CreateMatchLocationPickerState();
}

class _CreateMatchLocationPickerState
    extends State<_CreateMatchLocationPicker> {
  static const _fallbackCenter = ll.LatLng(30.1575, 71.5249);

  final _searchController = TextEditingController();
  final _mapController = fm.MapController();

  Timer? _searchDebounce;
  List<DiscoveryLocation> _results = const [];
  DiscoveryLocation? _selectedLocation;
  bool _searching = false;
  bool _findingCurrentLocation = false;
  bool _mapReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _mapController.dispose();
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

  Future<void> _search(String query) async {
    if (!mounted) return;

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final results = await widget.onSearch(query);
      if (!mounted || _searchController.text.trim() != query) return;

      setState(() {
        _results = results;
        _error = results.isEmpty ? 'No matching locations found.' : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _error = error.toString();
      });
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _selectLocation(DiscoveryLocation location) {
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _selectedLocation = location;
      _results = const [];
      _error = null;
      _searchController.text = location.label;
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
    });

    if (_mapReady) {
      _mapController.move(
        ll.LatLng(location.latitude, location.longitude),
        15,
      );
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_findingCurrentLocation) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _findingCurrentLocation = true;
      _error = null;
    });

    try {
      final current = await widget.onCurrentLocation();
      var resolved = current;

      try {
        final reverseResults = await widget.onSearch(
          '${current.latitude.toStringAsFixed(6)},'
          '${current.longitude.toStringAsFixed(6)}',
        );
        if (reverseResults.isNotEmpty) {
          final first = reverseResults.first;
          resolved = DiscoveryLocation(
            label: first.label,
            latitude: current.latitude,
            longitude: current.longitude,
            city: first.city,
            state: first.state,
            zipCode: first.zipCode,
          );
        }
      } catch (_) {
        // Precise coordinates are still valid even if a display address
        // cannot be resolved.
      }

      if (!mounted) return;
      _selectLocation(resolved);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _findingCurrentLocation = false);
    }
  }

  Future<void> _placePin(ll.LatLng point) async {
    final provisional = DiscoveryLocation(
      label: 'Pinned location',
      latitude: point.latitude,
      longitude: point.longitude,
    );

    setState(() {
      _selectedLocation = provisional;
      _results = const [];
      _error = null;
      _searchController.text = 'Pinned location';
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
    });

    try {
      final reverseResults = await widget.onSearch(
        '${point.latitude.toStringAsFixed(6)},'
        '${point.longitude.toStringAsFixed(6)}',
      );
      if (!mounted || reverseResults.isEmpty) return;

      final first = reverseResults.first;
      final resolved = DiscoveryLocation(
        label: first.label,
        latitude: point.latitude,
        longitude: point.longitude,
        city: first.city,
        state: first.state,
        zipCode: first.zipCode,
      );

      setState(() {
        _selectedLocation = resolved;
        _searchController.text = resolved.label;
        _searchController.selection = TextSelection.collapsed(
          offset: _searchController.text.length,
        );
      });
    } catch (_) {
      // Keep the valid manually selected coordinates if reverse lookup fails.
    }
  }

  void _confirm() {
    final selected = _selectedLocation;
    if (selected == null) {
      setState(() => _error = 'Choose a location before continuing.');
      return;
    }

    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final selected = _selectedLocation;
    final initialCenter = selected == null
        ? _fallbackCenter
        : ll.LatLng(selected.latitude, selected.longitude);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: FractionallySizedBox(
        heightFactor: 0.92,
        child: Material(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheetTop),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.controlBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal,
                  14,
                  AppSpacing.pageHorizontal,
                  12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Choose Location',
                        style: AppTypography.homeGreeting,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final reservedHeight = selected == null ? 268.0 : 336.0;
                    final responsiveMapHeight =
                        (constraints.maxHeight - reservedHeight)
                            .clamp(220.0, 420.0)
                            .toDouble();

                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pageHorizontal,
                        0,
                        AppSpacing.pageHorizontal,
                        AppSpacing.lg,
                      ),
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: _searchController,
                        hintText: 'Search area, address or venue',
                        leadingIcon: Icons.search_rounded,
                        textInputAction: TextInputAction.search,
                        onChanged: _onSearchChanged,
                        onFieldSubmitted: (value) {
                          final query = value.trim();
                          if (query.length >= 2) {
                            _searchDebounce?.cancel();
                            unawaited(_search(query));
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _CurrentLocationRow(
                        loading: _findingCurrentLocation,
                        onTap: _findingCurrentLocation
                            ? null
                            : _useCurrentLocation,
                      ),
                      if (_searching) ...[
                        const SizedBox(height: AppSpacing.sm),
                        const LinearProgressIndicator(
                          minHeight: 2,
                          color: AppColors.primary,
                        ),
                      ],
                      if (_results.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _SearchResults(
                          results: _results,
                          onSelect: _selectLocation,
                        ),
                      ],
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
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Choose on map',
                              style: AppTypography.homeMatchTitle18,
                            ),
                          ),
                          Text(
                            'Tap to place pin',
                            style: AppTypography.homeMeta12,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        height: responsiveMapHeight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          child: fm.FlutterMap(
                            mapController: _mapController,
                            options: fm.MapOptions(
                              initialCenter: initialCenter,
                              initialZoom: selected == null ? 12 : 15,
                              minZoom: 3,
                              maxZoom: 18,
                              backgroundColor: const Color(0xFFFFFCF8),
                              onMapReady: () => _mapReady = true,
                              onTap: (tapPosition, point) {
                                unawaited(_placePin(point));
                              },
                            ),
                            children: [
                              fm.TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.mahj_app',
                                tileBuilder: _styledOsmTile,
                              ),
                              if (selected != null)
                                fm.MarkerLayer(
                                  markers: [
                                    fm.Marker(
                                      point: ll.LatLng(
                                        selected.latitude,
                                        selected.longitude,
                                      ),
                                      width: 58,
                                      height: 66,
                                      alignment: Alignment.topCenter,
                                      child: Image.asset(
                                        AppAssets.mapMatchMarkerPng,
                                        width: 54,
                                        height: 61,
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.high,
                                      ),
                                    ),
                                  ],
                                ),
                              const fm.RichAttributionWidget(
                                attributions: [
                                  fm.TextSourceAttribution(
                                    'OpenStreetMap contributors',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (selected != null)
                        AppSurfaceContainer(
                          minHeight: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.10,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  selected.label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.homeMeta14.copyWith(
                                    color: AppColors.heading,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 20,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton.primary(
                        label: 'Confirm Location',
                        onPressed: selected == null ? null : _confirm,
                        isEnabled: selected != null,
                      ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _styledOsmTile(
    BuildContext context,
    Widget tileWidget,
    fm.TileImage tile,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.72,
            0,
            0,
            0,
            64,
            0,
            0.72,
            0,
            0,
            62,
            0,
            0,
            0.72,
            0,
            58,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: tileWidget,
        ),
        const ColoredBox(color: Color(0x0DEC5D01)),
      ],
    );
  }
}

class _CurrentLocationRow extends StatelessWidget {
  const _CurrentLocationRow({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceContainer(
      onTap: onTap,
      semanticsLabel: 'Use current location',
      minHeight: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(
                    Icons.my_location_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use Current Location',
                  style: AppTypography.homeMeta14.copyWith(
                    color: AppColors.heading,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Use your device location',
                  style: AppTypography.homeMeta12,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.results, required this.onSelect});

  final List<DiscoveryLocation> results;
  final ValueChanged<DiscoveryLocation> onSelect;

  @override
  Widget build(BuildContext context) {
    final visibleResults = results.take(5).toList(growable: false);

    return AppSurfaceContainer(
      minHeight: 0,
      padding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 180),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: visibleResults.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final location = visibleResults[index];

            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 2,
              ),
              leading: const Icon(
                Icons.location_on_outlined,
                size: 22,
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
              onTap: () => onSelect(location),
            );
          },
        ),
      ),
    );
  }
}
