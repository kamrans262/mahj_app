import 'package:flutter/foundation.dart';

import '../domain/match_filters.dart';

class MatchDiscoveryStore extends ChangeNotifier {
  MatchFilters _filters = MatchFilters.defaults();

  MatchFilters get filters => _filters;

  void update(MatchFilters filters, {bool notify = true}) {
    if (_filters == filters) return;

    _filters = filters;
    if (notify) {
      notifyListeners();
    }
  }

  void reset() {
    update(MatchFilters.defaults());
  }
}
