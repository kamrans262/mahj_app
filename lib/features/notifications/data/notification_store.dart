import 'package:flutter/foundation.dart';

import '../domain/mahj_notification.dart';
import 'notification_repository.dart';

class NotificationStore extends ChangeNotifier {
  NotificationStore({required NotificationRepository repository})
    : _repository = repository;

  final NotificationRepository _repository;

  List<MahjNotification> _notifications = const [];
  int _page = 0;
  int _unreadCount = 0;
  bool _hasMore = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  List<MahjNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasLoaded => _page > 0;

  Future<void> ensureLoaded() async {
    if (hasLoaded || _isLoading) return;
    await refresh();
  }

  Future<void> refresh() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _repository.list();
      _notifications = page.notifications;
      _page = page.page;
      _hasMore = page.hasMore;
      _unreadCount = page.unreadCount;
    } catch (_) {
      if (_notifications.isEmpty) {
        _errorMessage = 'Could not load notifications. Please try again.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUnreadCount() async {
    try {
      final count = await _repository.unreadCount();
      if (count == _unreadCount) return;
      _unreadCount = count;
      notifyListeners();
    } catch (_) {
      // Keep the last known badge count and retry on the next poll.
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || _isLoading || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final next = await _repository.list(page: _page + 1);
      final byId = <String, MahjNotification>{
        for (final item in _notifications) item.id: item,
        for (final item in next.notifications) item.id: item,
      };
      _notifications = byId.values.toList(growable: false)
        ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
      _page = next.page;
      _hasMore = next.hasMore;
      _unreadCount = next.unreadCount;
    } catch (_) {
      // Keep already loaded notifications visible. A later scroll can retry.
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<MahjNotification> markRead(MahjNotification notification) async {
    if (notification.isRead) return notification;

    final result = await _repository.markRead(notification.id);
    final index = _notifications.indexWhere(
      (item) => item.id == notification.id,
    );
    if (index >= 0) {
      final updated = List<MahjNotification>.of(_notifications);
      updated[index] = result.notification;
      _notifications = List<MahjNotification>.unmodifiable(updated);
    }
    _unreadCount = result.unreadCount;
    notifyListeners();

    return result.notification;
  }

  void clear() {
    _notifications = const [];
    _page = 0;
    _unreadCount = 0;
    _hasMore = false;
    _isLoading = false;
    _isLoadingMore = false;
    _errorMessage = null;
    notifyListeners();
  }
}
