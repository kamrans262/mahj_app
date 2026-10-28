import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tracks whether the first-visit Map radius picker has already been shown.
/// This is an app-install preference, not a per-login or per-screen flag.
abstract interface class MapRadiusIntroStore {
  Future<bool> hasBeenShown();
  Future<void> markShown();
}

class SecureMapRadiusIntroStore implements MapRadiusIntroStore {
  SecureMapRadiusIntroStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  /// Reuse a single instance across Map tab rebuilds and navigation so that
  /// a pending storage write never causes the picker to open a second time.
  static final SecureMapRadiusIntroStore shared = SecureMapRadiusIntroStore();

  static const _shownKey = 'mahj_map_radius_intro_shown_v1';

  final FlutterSecureStorage _storage;
  bool _shownInSession = false;

  @override
  Future<bool> hasBeenShown() async {
    if (_shownInSession) return true;

    try {
      final stored = await _storage.read(key: _shownKey) == 'true';
      // A manual tap may have marked the sheet shown while the read was in
      // flight. Never turn that in-memory decision back to false.
      _shownInSession = _shownInSession || stored;
    } on MissingPluginException {
      // Widget tests/unsupported platforms still retain the session state.
    } on PlatformException {
      // Do not prevent the map from working when secure storage is unavailable.
    }
    return _shownInSession;
  }

  @override
  Future<void> markShown() async {
    // Mark it before awaiting platform storage, so navigating away and back
    // cannot open the sheet twice during an in-flight write.
    _shownInSession = true;
    try {
      await _storage.write(key: _shownKey, value: 'true');
    } on MissingPluginException {
      // Keep the session value if the plugin is unavailable.
    } on PlatformException {
      // Keep the session value if the device rejects storage temporarily.
    }
  }
}
