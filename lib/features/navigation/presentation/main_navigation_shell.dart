import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../home/domain/home_match.dart';
import '../../home/presentation/home_screen.dart';
import '../../home/presentation/widgets/app_bottom_navigation.dart';
import '../../map/presentation/map_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({
    super.key,
    this.initialIndex = 0,
    this.onNearbyViewAll,
    this.onCreateMatch,
    this.onMatchTap,
  });

  final int initialIndex;
  final VoidCallback? onNearbyViewAll;
  final VoidCallback? onCreateMatch;
  final ValueChanged<HomeMatch>? onMatchTap;

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;
  bool _homeOverlayOpen = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex == 1 ? 1 : 0;
  }

  void _selectTab(int index) {
    if (index > 1 || index == _currentIndex) return;

    setState(() => _currentIndex = index);
  }

  void _setHomeOverlayVisible(bool visible) {
    if (_homeOverlayOpen == visible) return;

    setState(() => _homeOverlayOpen = visible);
  }

  @override
  Widget build(BuildContext context) {
    final showHomeActions = _currentIndex == 0 && !_homeOverlayOpen;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            onNearbyViewAll: widget.onNearbyViewAll,
            onMatchTap: widget.onMatchTap,
            onCreateMatch: widget.onCreateMatch,
            showBottomNavigation: false,
            showCreateFab: false,
            onFilterVisibilityChanged: _setHomeOverlayVisible,
          ),
          MapScreen(
            onBack: () => _selectTab(0),
            onViewDetails: widget.onMatchTap,
          ),
        ],
      ),
      floatingActionButton: showHomeActions
          ? FloatingActionButton(
              heroTag: 'main-shell-create-match-fab',
              onPressed: widget.onCreateMatch,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              tooltip: 'Create match',
              child: const Icon(Icons.add, size: 30),
            )
          : null,
      bottomNavigationBar: _homeOverlayOpen
          ? null
          : AppBottomNavigation(currentIndex: _currentIndex, onTap: _selectTab),
    );
  }
}
