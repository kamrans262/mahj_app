import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

/// A checkout callback only identifies the Stripe session to verify.
/// Opening a deep link never grants membership by itself.
class CheckoutReturn {
  const CheckoutReturn.success(this.sessionId) : cancelled = false;

  const CheckoutReturn.cancelled()
    : sessionId = null,
      cancelled = true;

  final String? sessionId;
  final bool cancelled;

  static final RegExp _sessionPattern = RegExp(
    r'^cs_(?:test|live)_[A-Za-z0-9_]+$',
  );

  static CheckoutReturn? fromUri(Uri uri) {
    if (uri.scheme != 'mahjaroundtown' || uri.host != 'billing') {
      return null;
    }

    if (uri.path == '/cancel') {
      return const CheckoutReturn.cancelled();
    }

    if (uri.path != '/success') return null;

    final sessionId = uri.queryParameters['session_id'];
    if (sessionId == null || !_sessionPattern.hasMatch(sessionId)) {
      return null;
    }

    return CheckoutReturn.success(sessionId);
  }
}

/// Starts before the Flutter UI so a return from a terminated app is retained
/// until the subscription screen is ready to verify it.
class CheckoutReturnStore extends ChangeNotifier {
  StreamSubscription<Uri>? _subscription;
  CheckoutReturn? _pending;

  void start() {
    if (_subscription != null) return;
    // app_links sends both the initial deep link and subsequent links.
    _subscription = AppLinks().uriLinkStream.listen(
      accept,
      onError: (Object error) {
        // The billing screens retain their existing lifecycle-resume fallback.
      },
    );
  }

  void accept(Uri uri) {
    final parsed = CheckoutReturn.fromUri(uri);
    if (parsed == null) return;
    _pending = parsed;
    notifyListeners();
  }

  CheckoutReturn? take() {
    final result = _pending;
    _pending = null;
    return result;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
