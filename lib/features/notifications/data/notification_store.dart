import 'package:flutter/foundation.dart';

import '../domain/mahj_notification.dart';
import 'notification_repository.dart';

class NotificationStore extends ChangeNotifier {
  NotificationStore({required NotificationRepository repository})
    : this._(repository);

  NotificationStore._(this._repository);

  final NotificationRepository _repository;

  List<MahjNotification> _notifications = const [];
  int _page = 0;
  int _unreadCount = 0;
  bool _hasMore = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isClearingAll = false;
  int _historyVersion = 0;
  String? _errorMessage;

  List<MahjNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isClearingAll => _isClearingAll;
  String? get errorMessage => _errorMessage;
  bool get hasLoaded => _page > 0;

  Future<void> ensureLoaded() async {
    if (hasLoaded || _isLoading) return;
    await refresh();
  }

  Future<void> refresh() async {
    if (_isLoading || _isClearingAll) return;
    final version = _historyVersion;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _repository.list();
      if (version != _historyVersion) return;
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
    if (_isClearingAll) return;
    final version = _historyVersion;
    try {
      final count = await _repository.unreadCount();
      if (version != _historyVersion || count == _unreadCount) return;
      _unreadCount = count;
      notifyListeners();
    } catch (_) {
      // Keep the last known badge count and retry on the next poll.
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || _isLoading || _isClearingAll || !_hasMore) return;
    final version = _historyVersion;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final next = await _repository.list(page: _page + 1);
      if (version != _historyVersion) return;
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
    if (notification.isRead || _isClearingAll) return notification;
    final version = _historyVersion;
    final result = await _repository.markRead(notification.id);
    if (version != _historyVersion) return notification;
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

  Future<void> deleteNotification(MahjNotification notification) async {
    if (_isClearingAll) return;
    final version = _historyVersion;
    // Only remove the row after the backend confirms deletion.
    final result = await _repository.deleteNotification(notification.id);
    if (version != _historyVersion) return;
    _notifications = List<MahjNotification>.unmodifiable(
      _notifications.where((item) => item.id != notification.id),
    );
    _unreadCount = result.unreadCount;
    notifyListeners();
  }

  Future<void> clearAllNotifications() async {
    if (_isClearingAll) return;
    _isClearingAll = true;
    // In-flight pagination/count requests cannot repopulate cleared history.
    _historyVersion++;
    notifyListeners();

    try {
      await _repository.clearAllNotifications();
      _notifications = const [];
      _page = 1;
      _hasMore = false;
      _unreadCount = 0;
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      // Keep existing notifications on a network/server failure.
      rethrow;
    } finally {
      _isClearingAll = false;
      notifyListeners();
    }
  }

  void clear() {
    _historyVersion++;
    _isClearingAll = false;
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
