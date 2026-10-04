import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_surface_container.dart';
import '../../home/domain/home_match.dart';
import '../../home/domain/match_filters.dart';
import '../../home/presentation/home_date_time_formatter.dart';
import '../../home/presentation/widgets/match_card.dart';
import '../../home/presentation/widgets/player_avatar_stack.dart';
import '../../home/presentation/widgets/sport_icon.dart';
import '../data/map_preview_data.dart';
import '../domain/map_match_marker.dart';
import 'widgets/demo_match_map.dart';
import 'widgets/live_match_map.dart';
import 'widgets/map_filter_chip.dart';

enum MapDateFilter { today, tomorrow }

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    this.markers,
    this.filters,
    this.onBack,
    this.onViewDetails,
    this.onDateFilterChanged,
    this.onRadiusChanged,
    this.onFiltersChanged,
    this.isLoading = false,
    this.useLiveMap = false,
  });

  final List<MapMatchMarker>? markers;
  final MatchFilters? filters;
  final VoidCallback? onBack;
  final ValueChanged<HomeMatch>? onViewDetails;
  final ValueChanged<MapDateFilter>? onDateFilterChanged;
  final ValueChanged<int>? onRadiusChanged;
  final Future<void> Function(MatchFilters filters)? onFiltersChanged;
  final bool isLoading;
  final bool useLiveMap;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _radiusOptions = <int>[1, 5, 10];
  static const _dateOptions = <MatchDateFilter>[
    MatchDateFilter.today,
    MatchDateFilter.tomorrow,
    MatchDateFilter.weekend,
    MatchDateFilter.nextThreeDays,
    MatchDateFilter.any,
  ];

  late MatchFilters _filters;
  String? _selectedMatchId;
  late final List<MapMatchMarker> _previewMarkers;

  List<MapMatchMarker> get _sourceMarkers => widget.markers ?? _previewMarkers;

  List<MapMatchMarker> get _visibleMarkers {
    return _sourceMarkers
        .where(
          (marker) =>
              marker.distanceMiles <= _filters.radiusMiles &&
              _matchesDateFilter(marker.match.startsAt, _filters.dateFilter),
        )
        .toList(growable: false);
  }

  bool _matchesDateFilter(DateTime value, MatchDateFilter filter) {
    if (filter == MatchDateFilter.any) return true;

    final now = DateTime.now();
    final localValue = value.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final matchDay = DateTime(
      localValue.year,
      localValue.month,
      localValue.day,
    );

    if (filter == MatchDateFilter.today) {
      return matchDay == today;
    }
    if (filter == MatchDateFilter.tomorrow) {
      return matchDay == today.add(const Duration(days: 1));
    }
    if (filter == MatchDateFilter.nextThreeDays) {
      final lastDay = today.add(const Duration(days: 2));
      return !matchDay.isBefore(today) && !matchDay.isAfter(lastDay);
    }

    var weekendStart = today;
    if (today.weekday == DateTime.sunday) {
      weekendStart = today.subtract(const Duration(days: 1));
    } else if (today.weekday != DateTime.saturday) {
      weekendStart = today.add(
        Duration(days: DateTime.saturday - today.weekday),
      );
    }
    final weekendEnd = weekendStart.add(const Duration(days: 1));

    return !matchDay.isBefore(weekendStart) && !matchDay.isAfter(weekendEnd);
  }

  MapMatchMarker? get _selectedMarker {
    final visible = _visibleMarkers;
    if (visible.isEmpty) return null;

    for (final marker in visible) {
      if (marker.match.id == _selectedMatchId) {
        return marker;
      }
    }

    return visible.first;
  }

  @override
  void initState() {
    super.initState();
    _previewMarkers = MapPreviewData.create();
    _filters =
        widget.filters ??
        MatchFilters.defaults().copyWith(
          radiusMiles: 10,
          dateFilter: MatchDateFilter.today,
          showOpenOnly: false,
        );
    final markers = _visibleMarkers;
    _selectedMatchId = markers.isEmpty ? null : markers.first.match.id;
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final incomingFilters = widget.filters;
    if (incomingFilters != null && incomingFilters != oldWidget.filters) {
      _filters = incomingFilters;
    }

    final markers = _visibleMarkers;
    if (markers.isEmpty) {
      _selectedMatchId = null;
      return;
    }

    final stillExists = markers.any(
      (marker) => marker.match.id == _selectedMatchId,
    );
    if (!stillExists) {
      _selectedMatchId = markers.first.match.id;
    }
  }

  Future<void> _applyFilters(MatchFilters next) async {
    setState(() {
      _filters = next;
      final visible = _visibleMarkers;
      final selectedStillVisible = visible.any(
        (marker) => marker.match.id == _selectedMatchId,
      );
      if (!selectedStillVisible) {
        _selectedMatchId = visible.isEmpty ? null : visible.first.match.id;
      }
    });

    final callback = widget.onFiltersChanged;
    if (callback != null) {
      await callback(next);
    }
  }

  Future<void> _toggleDateFilter() async {
    final currentIndex = _dateOptions.indexOf(_filters.dateFilter);
    final nextIndex = currentIndex < 0
        ? 0
        : (currentIndex + 1) % _dateOptions.length;
    final nextFilter = _dateOptions[nextIndex];

    await _applyFilters(_filters.copyWith(dateFilter: nextFilter));

    if (nextFilter == MatchDateFilter.today) {
      widget.onDateFilterChanged?.call(MapDateFilter.today);
    } else if (nextFilter == MatchDateFilter.tomorrow) {
      widget.onDateFilterChanged?.call(MapDateFilter.tomorrow);
    }
  }

  Future<void> _cycleRadius() async {
    final currentRadius = _filters.radiusMiles.round();
    final currentIndex = _radiusOptions.indexOf(currentRadius);
    final nextIndex = currentIndex < 0
        ? 0
        : (currentIndex + 1) % _radiusOptions.length;
    final next = _radiusOptions[nextIndex];

    await _applyFilters(_filters.copyWith(radiusMiles: next.toDouble()));
    widget.onRadiusChanged?.call(next);
  }

  void _selectMarker(MapMatchMarker marker) {
    if (_selectedMatchId == marker.match.id) return;
    setState(() => _selectedMatchId = marker.match.id);
  }

  String get _dateFilterLabel => _filters.dateFilter.label;

  String get _radiusLabel {
    final miles = _filters.radiusMiles.round();
    return miles == 1 ? '1 mile' : '$miles miles';
  }

  Widget _buildMap(List<MapMatchMarker> visibleMarkers) {
    if (!widget.useLiveMap) {
      return DemoMatchMap(
        key: const ValueKey('map-demo-canvas'),
        markers: visibleMarkers,
        selectedMatchId: _selectedMarker?.match.id,
        onMarkerTap: _selectMarker,
        isLoading: widget.isLoading,
      );
    }

    return LiveMatchMap(
      key: const ValueKey('map-live-canvas'),
      markers: visibleMarkers,
      selectedMatchId: _selectedMarker?.match.id,
      onMarkerTap: _selectMarker,
      centerLatitude: _filters.latitude,
      centerLongitude: _filters.longitude,
      currentLocationLatitude: _filters.usesCurrentLocation
          ? _filters.latitude
          : null,
      currentLocationLongitude: _filters.usesCurrentLocation
          ? _filters.longitude
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleMarkers = _visibleMarkers;
    final selected = _selectedMarker;

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
                title: 'Map',
                onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pageHorizontal,
                        AppSpacing.lg,
                        AppSpacing.pageHorizontal,
                        0,
                      ),
                      child: Row(
                        children: [
                          MapFilterChip(
                            label: _dateFilterLabel,
                            semanticLabel: 'Date filter',
                            onTap: () {
                              _toggleDateFilter();
                            },
                          ),
                          const SizedBox(width: 14),
                          MapFilterChip(
                            label: _radiusLabel,
                            semanticLabel: 'Distance radius filter',
                            onTap: () {
                              _cycleRadius();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      key: const ValueKey('map-full-width-slot'),
                      width: double.infinity,
                      child: AspectRatio(
                        aspectRatio: 0.82,
                        child: _buildMap(visibleMarkers),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pageHorizontal,
                        0,
                        AppSpacing.pageHorizontal,
                        AppSpacing.lg,
                      ),
                      child: widget.isLoading && selected == null
                          ? const _MapStateCard(
                              message: 'Loading nearby matches...',
                            )
                          : selected == null
                          ? const _MapStateCard(
                              message: 'No matches found in this area',
                            )
                          : _SelectedMatchDetails(
                              key: const ValueKey('map-detail-body'),
                              marker: selected,
                              onViewDetails: widget.onViewDetails,
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

class _SelectedMatchDetails extends StatelessWidget {
  const _SelectedMatchDetails({
    required this.marker,
    required this.onViewDetails,
    super.key,
  });

  final MapMatchMarker marker;
  final ValueChanged<HomeMatch>? onViewDetails;

  @override
  Widget build(BuildContext context) {
    final match = marker.match;

    return AppSurfaceContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SportIcon(match: match, size: 40),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.sportName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.homeMatchTitle18,
                  ),
                  const SizedBox(height: AppSpacing.micro),
                  Text(
                    HomeDateTimeFormatter.featuredSchedule(match.startsAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.homeMeta14,
                  ),
                  if (match.distanceMiles != null) ...[
                    const SizedBox(height: AppSpacing.micro),
                    Text(
                      '${match.distanceMiles!.toStringAsFixed(1)} miles away',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.homeMeta12,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _MapMatchMetadata(match: match),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final shouldStack = constraints.maxWidth < 300 || textScale > 1.35;

            final players = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PlayerAvatarStack(assetPaths: marker.playerAvatarAssets),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    '${match.currentPlayers}/${match.maxPlayers} Players',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.homeMeta14,
                  ),
                ),
              ],
            );

            final details = AppButton.compactPrimary(
              label: 'View Details',
              onPressed: onViewDetails == null
                  ? null
                  : () => onViewDetails!(match),
            );

            if (shouldStack) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  players,
                  const SizedBox(height: AppSpacing.sm),
                  Align(alignment: Alignment.centerRight, child: details),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: players),
                const SizedBox(width: AppSpacing.sm),
                details,
              ],
            );
          },
        ),
        ],
      ),
    );
  }
}

class _MapMatchMetadata extends StatelessWidget {
  const _MapMatchMetadata({required this.match});

  final HomeMatch match;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final items = <Widget>[
          MatchMetadataItem(
            icon: Icons.calendar_today,
            text: HomeDateTimeFormatter.compactDate(match.startsAt),
            iconColor: AppColors.textSecondary,
          ),
          MatchMetadataItem(
            icon: Icons.access_time,
            text: HomeDateTimeFormatter.time(match.startsAt),
            iconColor: AppColors.textSecondary,
          ),
          MatchMetadataItem(
            text: '${match.currentPlayers}/${match.maxPlayers} Players',
          ),
        ];

        if (constraints.maxWidth < 315) {
          return Wrap(spacing: 16, runSpacing: 10, children: items);
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: items[0]),
            const SizedBox(width: AppSpacing.xs),
            Flexible(child: items[1]),
            const SizedBox(width: AppSpacing.xs),
            Flexible(child: items[2]),
          ],
        );
      },
    );
  }
}

class _MapStateCard extends StatelessWidget {
  const _MapStateCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceContainer(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTypography.homeMeta14,
      ),
    );
  }
}
