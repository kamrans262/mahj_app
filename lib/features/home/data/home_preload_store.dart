import '../domain/home_match.dart';
import '../domain/match_filters.dart';
import '../../matches/data/match_repository.dart';
import 'location_repository.dart';
import 'match_discovery_store.dart';

class HomePreloadSnapshot {
  const HomePreloadSnapshot({
    required this.liveMatches,
    required this.discoveryMatches,
    required this.filters,
  });

  final List<HomeMatch> liveMatches;
  final List<HomeMatch> discoveryMatches;
  final MatchFilters filters;
}

class HomePreloadStore {
  factory HomePreloadStore({
    required MatchRepository matchRepository,
    required LocationRepository locationRepository,
    required MatchDiscoveryStore discoveryStore,
  }) {
    return HomePreloadStore._(
      matchRepository,
      locationRepository,
      discoveryStore,
    );
  }

  HomePreloadStore._(
    this._matchRepository,
    this._locationRepository,
    this._discoveryStore,
  );

  final MatchRepository _matchRepository;
  final LocationRepository _locationRepository;
  final MatchDiscoveryStore _discoveryStore;

  HomePreloadSnapshot? _snapshot;

  HomePreloadSnapshot? get snapshot => _snapshot;

  Future<HomePreloadSnapshot> preload() async {
    final liveFuture = _safeMatches(_matchRepository.list());

    var filters = _discoveryStore.filters;
    if (filters.usesCurrentLocation && !filters.hasCoordinates) {
      final current = await _locationRepository.currentLocationIfGranted();
      if (current != null) {
        filters = filters.copyWith(
          selectedLocation: current.label,
          latitude: current.latitude,
          longitude: current.longitude,
        );
        _discoveryStore.update(filters, notify: false);
      }
    }

    final discoveryFuture = _safeMatches(
      _matchRepository.list(filters: filters),
    );

    final results = await Future.wait<List<HomeMatch>>([
      liveFuture,
      discoveryFuture,
    ]);

    final snapshot = HomePreloadSnapshot(
      liveMatches: List<HomeMatch>.unmodifiable(results[0]),
      discoveryMatches: List<HomeMatch>.unmodifiable(results[1]),
      filters: filters,
    );
    _snapshot = snapshot;
    return snapshot;
  }

  void update({
    required List<HomeMatch> liveMatches,
    required List<HomeMatch> discoveryMatches,
    required MatchFilters filters,
  }) {
    _snapshot = HomePreloadSnapshot(
      liveMatches: List<HomeMatch>.unmodifiable(liveMatches),
      discoveryMatches: List<HomeMatch>.unmodifiable(discoveryMatches),
      filters: filters,
    );
  }

  void clear() {
    _snapshot = null;
  }

  Future<List<HomeMatch>> _safeMatches(Future<List<HomeMatch>> request) async {
    try {
      return await request;
    } catch (_) {
      return const <HomeMatch>[];
    }
  }
}
