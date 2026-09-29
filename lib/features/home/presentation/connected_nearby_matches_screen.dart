import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../matches/data/match_repository.dart';
import '../domain/home_match.dart';
import 'all_nearby_matches_screen.dart';

class ConnectedNearbyMatchesScreen extends StatefulWidget {
  const ConnectedNearbyMatchesScreen({
    required this.repository,
    super.key,
    this.onBack,
    this.onMatchTap,
    this.onCreateMatch,
  });

  final MatchRepository repository;
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
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final matches = await widget.repository.list();
      if (!mounted) return;
      setState(() => _matches = matches);
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

  @override
  Widget build(BuildContext context) {
    return AllNearbyMatchesScreen(
      matches: _matches,
      onBack: widget.onBack,
      onMatchTap: widget.onMatchTap,
      onCreateMatch: widget.onCreateMatch,
      onRefresh: _load,
      isLoading: _loading,
      errorMessage: _error,
    );
  }
}
