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
    this.initialFilters,
    this.locationRepository,
    this.onBack,
    this.onMatchTap,
    this.onCreateMatch,
  });

  final MatchRepository repository;
  final MatchDiscoveryStore? discoveryStore;
  final MatchFilters? initialFilters;
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

  @override
  void initState() {
    super.initState();
    _filters =
        widget.initialFilters ??
        widget.discoveryStore?.filters ??
        MatchFilters.defaults();
    _load();
  }

  Future<void> _load({MatchFilters? filters, String? query}) async {
    final activeFilters = filters ?? _filters;
    final activeQuery = query ?? _query;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final matches = await widget.repository.list(
        filters: activeFilters,
        query: activeQuery,
      );
      if (!mounted) return;
      setState(() {
        _filters = activeFilters;
        _query = activeQuery;
        _matches = matches;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException
            ? error.message
            : 'Could not load matches. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeFilters(MatchFilters filters) async {
    _filters = filters;
    if (widget.initialFilters == null) {
      widget.discoveryStore?.update(filters);
    }
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
    );
  }
}
