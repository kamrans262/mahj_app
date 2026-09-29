import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage, bool? useMemoryOnly})
    : _storage = storage ?? const FlutterSecureStorage(),
      _useMemoryOnly =
          useMemoryOnly ?? Platform.environment['FLUTTER_TEST'] == 'true';

  static const _tokenKey = 'mahj_auth_token';

  final FlutterSecureStorage _storage;
  final bool _useMemoryOnly;
  String? _testFallbackToken;

  @override
  Future<String?> read() async {
    if (_useMemoryOnly) return _testFallbackToken;

    try {
      return await _storage.read(key: _tokenKey);
    } on MissingPluginException {
      return _testFallbackToken;
    } on PlatformException {
      return _testFallbackToken;
    }
  }

  @override
  Future<void> write(String token) async {
    _testFallbackToken = token;
    if (_useMemoryOnly) return;

    try {
      await _storage.write(key: _tokenKey, value: token);
    } on MissingPluginException {
      // Widget tests and unsupported platforms use the in-memory fallback.
    } on PlatformException {
      // Preserve the in-memory fallback when secure storage is unavailable.
    }
  }

  @override
  Future<void> clear() async {
    _testFallbackToken = null;
    if (_useMemoryOnly) return;

    try {
      await _storage.delete(key: _tokenKey);
    } on MissingPluginException {
      // The in-memory token has already been cleared.
    } on PlatformException {
      // The in-memory token has already been cleared.
    }
  }
}
