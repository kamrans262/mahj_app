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

  List<MapMatchMarker> get _visibleMarkers {
    return _sourceMarkers
        .where((marker) => marker.distanceMiles <= _radiusMiles)
        .toList(growable: false);
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
    final markers = _sourceMarkers;
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

    setState(() => _dateFilter = next);
    widget.onDateFilterChanged?.call(next);
  }

  void _cycleRadius() {
    final currentIndex = _radiusOptions.indexOf(_radiusMiles);
    final nextIndex = (currentIndex + 1) % _radiusOptions.length;
    final next = _radiusOptions[nextIndex];

    setState(() {
      _radiusMiles = next;
      final visible = _visibleMarkers;
      _selectedMatchId = visible.isEmpty ? null : visible.first.match.id;
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
                padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
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
                    const SizedBox(height: AppSpacing.lg),
                    AspectRatio(
                      aspectRatio: 0.82,
                      child: DemoMatchMap(
                        key: const ValueKey('map-demo-canvas'),
                        markers: visibleMarkers,
                        selectedMatchId: selected?.match.id,
                        onMarkerTap: _selectMarker,
                        isLoading: widget.isLoading,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (widget.isLoading && selected == null)
                      const _MapStateCard(message: 'Loading nearby matches...')
                    else if (selected == null)
                      const _MapStateCard(
                        message: 'No matches found in this area',
                      )
                    else
                      _SelectedMatchCard(
                        key: const ValueKey('map-detail-card'),
                        marker: selected,
                        onViewDetails: widget.onViewDetails,
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

class _SelectedMatchCard extends StatelessWidget {
  const _SelectedMatchCard({
    required this.marker,
    required this.onViewDetails,
    super.key,
  });

  final MapMatchMarker marker;
  final ValueChanged<HomeMatch>? onViewDetails;

  @override
  Widget build(BuildContext context) {
    final match = marker.match;

    return MatchCard(
      match: match,
      showStatus: false,
      subtitle: HomeDateTimeFormatter.featuredSchedule(match.startsAt),
      titleStyle: AppTypography.homeMatchTitle18,
      sportIconSize: 40,
      footer: LayoutBuilder(
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
