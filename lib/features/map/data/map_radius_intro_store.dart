/// Tracks whether the Map radius picker has been shown during this app run.
///
/// This is intentionally kept in memory rather than secure storage: a full
/// app restart should show the picker again on the first Map visit.
abstract interface class MapRadiusIntroStore {
  Future<bool> hasBeenShown();
  Future<void> markShown();
}

/// Shared for the lifetime of this Dart app process, including tab changes
/// and widget rebuilds. A fresh app launch starts with a fresh instance.
class SessionMapRadiusIntroStore implements MapRadiusIntroStore {
  SessionMapRadiusIntroStore();

  static final SessionMapRadiusIntroStore shared =
      SessionMapRadiusIntroStore();

  bool _shownThisLaunch = false;

  @override
  Future<bool> hasBeenShown() async => _shownThisLaunch;

  @override
  Future<void> markShown() async {
    // Mark immediately so repeated Map navigation cannot open two sheets.
    _shownThisLaunch = true;
  }
}
