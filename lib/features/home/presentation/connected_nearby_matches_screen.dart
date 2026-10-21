import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../matches/data/match_repository.dart';
import '../data/location_repository.dart';
import '../data/match_discovery_store.dart';
import '../domain/home_match.dart';
import '../domain/match_filters.dart';
import 'all_nearby_matches_screen.dart';

class ConnectedNearbyMatchesScreen extends StatefulWidget {
  const ConnectedNearbyMatchesScreen({
    required this.repository,
    super.key,
    this.discoveryStore,
    this.locationRepository,
    this.onBack,
    this.onMatchTap,
    this.onCreateMatch,
  });

  final MatchRepository repository;
  final MatchDiscoveryStore? discoveryStore;
  final LocationRepository? locationRepository;
  final VoidCallback? onBack;
  final ValueChanged<HomeMatch>? onMatchTap;
  final VoidCallback? onCreateMatch;

  @override
  State<ConnectedNearbyMatchesScreen> createState() =>
      _ConnectedNearbyMatchesScreenState();
}

class _ConnectedNearbyMatchesScreenState
    extends State<ConnectedNearbyMatchesScreen> {
  List<HomeMatch> _matches = const [];
  late MatchFilters _filters;
  String _query = '';
  bool _loading = true;
  String? _error;
  String? _distanceNotice;
  int _loadVersion = 0;

  @override
  void initState() {
    super.initState();
    _filters = widget.discoveryStore?.filters ?? MatchFilters.defaults();
    _load();
  }

  Future<MatchFilters> _resolveDistanceLocation(MatchFilters filters) async {
    if (filters.sortOption != MatchSortOption.distance ||
        filters.hasCoordinates) {
      return filters;
    }

    final locations = widget.locationRepository;
    if (locations == null) return filters;

    try {
      if (filters.usesCurrentLocation) {
        final location = await locations.currentLocation();
        return filters.copyWith(
          selectedLocation: location.label,
          latitude: location.latitude,
          longitude: location.longitude,
        );
      }

      final results = await locations.search(filters.selectedLocation);
      if (results.isNotEmpty) {
        return filters.copyWith(
          latitude: results.first.latitude,
          longitude: results.first.longitude,
        );
      }
    } catch (_) {
      // A denied permission or failed geocoder must not masquerade as a
      // successful distance sort. Keep the list available with a warning.
    }
    return filters;
  }

  Future<void> _load({MatchFilters? filters, String? query}) async {
    final requestVersion = ++_loadVersion;
    final activeFilters = filters ?? _filters;
    final activeQuery = query ?? _query;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final resolvedFilters = await _resolveDistanceLocation(activeFilters);
      final missingDistanceOrigin =
          resolvedFilters.sortOption == MatchSortOption.distance &&
          !resolvedFilters.hasCoordinates;

      final matches = await widget.repository.list(
        filters: missingDistanceOrigin
            ? resolvedFilters.copyWith(sortOption: MatchSortOption.date)
            : resolvedFilters,
        query: activeQuery,
        discoverOnly: true,
      );
      if (!mounted || requestVersion != _loadVersion) return;
      widget.discoveryStore?.update(resolvedFilters, notify: false);
      setState(() {
        _filters = resolvedFilters;
        _query = activeQuery;
        _matches = matches;
        _distanceNotice = missingDistanceOrigin
            ? 'Select a city or ZIP code, or enable location access to sort by distance. Matches are shown by date until a location is available.'
            : null;
      });
    } catch (error) {
      if (!mounted || requestVersion != _loadVersion) return;
      setState(() {
        _error = error is ApiException
            ? error.message
            : 'Could not load matches. Please try again.';
      });
    } finally {
      if (mounted && requestVersion == _loadVersion) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _changeFilters(MatchFilters filters) async {
    _filters = filters;
    widget.discoveryStore?.update(filters);
    await _load(filters: filters);
  }

  @override
  Widget build(BuildContext context) {
    return AllNearbyMatchesScreen(
      matches: _matches,
      initialFilters: _filters,
      onBack: widget.onBack,
      onMatchTap: widget.onMatchTap,
      onCreateMatch: widget.onCreateMatch,
      onRefresh: _load,
      onSearch: (query) => _load(query: query),
      onFiltersChanged: _changeFilters,
      onLocationSearch: widget.locationRepository?.search,
      onCurrentLocation: widget.locationRepository?.currentLocation,
      isLoading: _loading,
      errorMessage: _error,
      distanceNotice: _distanceNotice,
    );
  }
}
