import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_surface_container.dart';
import '../../home/data/location_repository.dart';
import '../../home/domain/discovery_location.dart';

class LocationSettingsScreen extends StatefulWidget {
  const LocationSettingsScreen({
    required this.repository,
    super.key,
    this.onBack,
  });

  final LocationRepository repository;
  final VoidCallback? onBack;

  @override
  State<LocationSettingsScreen> createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> {
  bool _loading = true;
  bool _servicesEnabled = false;
  LocationPermission _permission = LocationPermission.denied;
  DiscoveryLocation? _location;
  String? _message;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    final servicesEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();
    final current = await widget.repository.currentLocationIfGranted();
    final location = current == null
        ? null
        : await _resolveLocationLabel(current);

    if (!mounted) return;
    setState(() {
      _servicesEnabled = servicesEnabled;
      _permission = permission;
      _location = location;
      _loading = false;
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final current = await widget.repository.currentLocation();
      final location = await _resolveLocationLabel(current);
      if (!mounted) return;
      setState(() {
        _location = location;
        _message = 'Current location is ready for nearby matches.';
      });
    } on LocationAccessException catch (error) {
      if (!mounted) return;
      setState(() => _message = error.message);
    } finally {
      if (mounted) {
        final services = await Geolocator.isLocationServiceEnabled();
        final permission = await Geolocator.checkPermission();
        setState(() {
          _servicesEnabled = services;
          _permission = permission;
          _loading = false;
        });
      }
    }
  }

  Future<DiscoveryLocation> _resolveLocationLabel(
    DiscoveryLocation current,
  ) async {
    try {
      final nativeResolved = await widget.repository.resolveMapTap(
        latitude: current.latitude,
        longitude: current.longitude,
      );
      if (nativeResolved != null && nativeResolved.label.trim().isNotEmpty) {
        return DiscoveryLocation(
          label: nativeResolved.label,
          latitude: current.latitude,
          longitude: current.longitude,
          city: nativeResolved.city,
          state: nativeResolved.state,
          zipCode: nativeResolved.zipCode,
        );
      }

      final results = await widget.repository.search(
        '${current.latitude.toStringAsFixed(6)},'
        '${current.longitude.toStringAsFixed(6)}',
      );
      if (results.isEmpty || results.first.label.trim().isEmpty) {
        return current;
      }

      final resolved = results.first;
      return DiscoveryLocation(
        label: resolved.label,
        latitude: current.latitude,
        longitude: current.longitude,
        city: resolved.city,
        state: resolved.state,
        zipCode: resolved.zipCode,
      );
    } catch (_) {
      return current;
    }
  }

  String get _permissionLabel {
    return switch (_permission) {
      LocationPermission.always => 'Allowed',
      LocationPermission.whileInUse => 'Allowed while using app',
      LocationPermission.denied => 'Permission needed',
      LocationPermission.deniedForever => 'Blocked in device settings',
      LocationPermission.unableToDetermine => 'Unable to determine',
    };
  }

  @override
  Widget build(BuildContext context) {
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
                title: 'Location Settings',
                onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: _loading && _location == null
                  ? const Center(child: AppLoader())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pageHorizontal,
                        25,
                        AppSpacing.pageHorizontal,
                        AppSpacing.xxl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Location Access',
                            style: AppTypography.title18,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppSurfaceContainer(
                            minHeight: 0,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              children: [
                                _LocationSettingRow(
                                  icon: Icons.location_on_outlined,
                                  title: 'Location Services',
                                  value: _servicesEnabled ? 'On' : 'Off',
                                  active: _servicesEnabled,
                                ),
                                const Divider(
                                  height: AppSpacing.xxl,
                                  color: AppColors.divider,
                                ),
                                _LocationSettingRow(
                                  icon: Icons.shield_outlined,
                                  title: 'App Permission',
                                  value: _permissionLabel,
                                  active:
                                      _permission ==
                                          LocationPermission.always ||
                                      _permission ==
                                          LocationPermission.whileInUse,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Current Location',
                            style: AppTypography.title18,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppSurfaceContainer(
                            minHeight: 0,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.my_location_rounded,
                                  size: 22,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _location?.label ??
                                        'Location has not been detected yet.',
                                    style: AppTypography.body14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_message != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              _message!,
                              textAlign: TextAlign.center,
                              style: AppTypography.homeMeta12.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xl),
                          AppButton.primary(
                            label: 'Use Current Location',
                            onPressed: _loading ? null : _useCurrentLocation,
                            isLoading: _loading,
                          ),
                          if (!_servicesEnabled ||
                              _permission == LocationPermission.deniedForever) ...[
                            const SizedBox(height: AppSpacing.md),
                            AppButton.secondary(
                              label: !_servicesEnabled
                                  ? 'Open Location Services'
                                  : 'Open App Settings',
                              onPressed: () async {
                                if (!_servicesEnabled) {
                                  await Geolocator.openLocationSettings();
                                } else {
                                  await Geolocator.openAppSettings();
                                }
                                if (mounted) await _refresh();
                              },
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Mahj uses your location to calculate distance, show nearby matches, and center the map. Your location is not shown as a live location to other players.',
                            style: AppTypography.homeMeta12,
                            textAlign: TextAlign.center,
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

class _LocationSettingRow extends StatelessWidget {
  const _LocationSettingRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.active,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: AppTypography.body16.copyWith(color: AppColors.heading),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          value,
          textAlign: TextAlign.right,
          style: AppTypography.homeMeta12.copyWith(
            color: active ? AppColors.primary : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
