import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_surface_container.dart';
import '../../home/domain/home_match.dart';
import '../../home/presentation/home_date_time_formatter.dart';
import '../../home/presentation/widgets/match_card.dart';
import '../../home/presentation/widgets/sport_icon.dart';
import '../../home/presentation/widgets/player_avatar_stack.dart';
import '../data/map_preview_data.dart';
import '../domain/map_match_marker.dart';
import 'widgets/demo_match_map.dart';
import 'widgets/map_filter_chip.dart';

enum MapDateFilter { today, tomorrow }

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    this.markers,
    this.onBack,
    this.onViewDetails,
    this.onDateFilterChanged,
    this.onRadiusChanged,
    this.isLoading = false,
  });

  final List<MapMatchMarker>? markers;
  final VoidCallback? onBack;
  final ValueChanged<HomeMatch>? onViewDetails;
  final ValueChanged<MapDateFilter>? onDateFilterChanged;
  final ValueChanged<int>? onRadiusChanged;
  final bool isLoading;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _radiusOptions = <int>[1, 5, 10];

  MapDateFilter _dateFilter = MapDateFilter.today;
  int _radiusMiles = 10;
  String? _selectedMatchId;
  late final List<MapMatchMarker> _previewMarkers;

  List<MapMatchMarker> get _sourceMarkers => widget.markers ?? _previewMarkers;

  List<MapMatchMarker> get _visibleMarkers =>
      _filteredMarkers(dateFilter: _dateFilter, radiusMiles: _radiusMiles);

  List<MapMatchMarker> _filteredMarkers({
    required MapDateFilter dateFilter,
    required int radiusMiles,
  }) {
    final now = DateTime.now();
    final targetDate = dateFilter == MapDateFilter.today
        ? now
        : now.add(const Duration(days: 1));

    return _sourceMarkers
        .where(
          (marker) =>
              marker.distanceMiles <= radiusMiles &&
              _isSameLocalDay(marker.match.startsAt, targetDate),
        )
        .toList(growable: false);
  }

  bool _isSameLocalDay(DateTime value, DateTime target) {
    final localValue = value.toLocal();
    final localTarget = target.toLocal();

    return localValue.year == localTarget.year &&
        localValue.month == localTarget.month &&
        localValue.day == localTarget.day;
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
    final markers = _visibleMarkers;
    _selectedMatchId = markers.isEmpty ? null : markers.first.match.id;
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

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

  void _toggleDateFilter() {
    final next = _dateFilter == MapDateFilter.today
        ? MapDateFilter.tomorrow
        : MapDateFilter.today;

    setState(() {
      _dateFilter = next;
      final visible = _filteredMarkers(
        dateFilter: next,
        radiusMiles: _radiusMiles,
      );
      _selectedMatchId = visible.isEmpty ? null : visible.first.match.id;
    });
    widget.onDateFilterChanged?.call(next);
  }

  void _cycleRadius() {
    final currentIndex = _radiusOptions.indexOf(_radiusMiles);
    final nextIndex = (currentIndex + 1) % _radiusOptions.length;
    final next = _radiusOptions[nextIndex];

    setState(() {
      final visible = _filteredMarkers(
        dateFilter: _dateFilter,
        radiusMiles: next,
      );
      _radiusMiles = next;

      final selectedStillVisible = visible.any(
        (marker) => marker.match.id == _selectedMatchId,
      );
      if (!selectedStillVisible) {
        _selectedMatchId = visible.isEmpty ? null : visible.first.match.id;
      }
    });

    widget.onRadiusChanged?.call(next);
  }

  void _selectMarker(MapMatchMarker marker) {
    if (_selectedMatchId == marker.match.id) return;

    setState(() => _selectedMatchId = marker.match.id);
  }

  String get _dateFilterLabel {
    return _dateFilter == MapDateFilter.today ? 'Today' : 'Tomorrow';
  }

  String get _radiusLabel {
    return _radiusMiles == 1 ? '1 mile' : '$_radiusMiles miles';
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
                            onTap: _toggleDateFilter,
                          ),
                          const SizedBox(width: 14),
                          MapFilterChip(
                            label: _radiusLabel,
                            semanticLabel: 'Distance radius filter',
                            onTap: _cycleRadius,
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
                        child: DemoMatchMap(
                          key: const ValueKey('map-demo-canvas'),
                          markers: visibleMarkers,
                          selectedMatchId: selected?.match.id,
                          onMarkerTap: _selectMarker,
                          isLoading: widget.isLoading,
                        ),
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

    return Column(
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
