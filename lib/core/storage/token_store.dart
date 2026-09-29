import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'mahj_auth_token';
  static const _operationTimeout = Duration(seconds: 2);

  final FlutterSecureStorage _storage;
  String? _testFallbackToken;

  @override
  Future<String?> read() async {
    try {
      return await _storage.read(key: _tokenKey).timeout(_operationTimeout);
    } on MissingPluginException {
      return _testFallbackToken;
    } on PlatformException {
      return _testFallbackToken;
    } on TimeoutException {
      return _testFallbackToken;
    }
  }

  @override
  Future<void> write(String token) async {
    _testFallbackToken = token;
    try {
      await _storage
          .write(key: _tokenKey, value: token)
          .timeout(_operationTimeout);
    } on MissingPluginException {
      // Widget tests do not register the platform plugin.
    } on PlatformException {
      // Preserve the in-memory fallback when secure storage is unavailable.
    } on TimeoutException {
      // Preserve the in-memory fallback when secure storage is slow.
    }
  }

  @override
  Future<void> clear() async {
    _testFallbackToken = null;
    try {
      await _storage.delete(key: _tokenKey).timeout(_operationTimeout);
    } on MissingPluginException {
      // Widget tests do not register the platform plugin.
    } on PlatformException {
      // The in-memory token has already been cleared.
    } on TimeoutException {
      // The in-memory token has already been cleared.
    }
  }
}
