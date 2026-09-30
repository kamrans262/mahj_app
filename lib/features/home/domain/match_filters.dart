enum MatchSortOption { distance, date }

enum MatchDateFilter { any, today, tomorrow, weekend, nextThreeDays }

extension MatchSortOptionX on MatchSortOption {
  String get apiValue => switch (this) {
    MatchSortOption.distance => 'distance',
    MatchSortOption.date => 'date',
  };

  String get label => switch (this) {
    MatchSortOption.distance => 'Distance',
    MatchSortOption.date => 'Date',
  };
}

extension MatchDateFilterX on MatchDateFilter {
  String get apiValue => switch (this) {
    MatchDateFilter.any => 'any',
    MatchDateFilter.today => 'today',
    MatchDateFilter.tomorrow => 'tomorrow',
    MatchDateFilter.weekend => 'weekend',
    MatchDateFilter.nextThreeDays => 'next_3_days',
  };

  String get label => switch (this) {
    MatchDateFilter.any => 'Any Date',
    MatchDateFilter.today => 'Today',
    MatchDateFilter.tomorrow => 'Tomorrow',
    MatchDateFilter.weekend => 'This Weekend',
    MatchDateFilter.nextThreeDays => 'Next 3 Days',
  };
}

class MatchFilters {
  const MatchFilters({
    required this.selectedLocation,
    required this.radiusMiles,
    required this.showOpenOnly,
    required this.sortOption,
    required this.dateFilter,
    this.latitude,
    this.longitude,
  });

  static const String defaultLocation = 'Current Location';
  static const double minRadiusMiles = 1;
  static const double maxRadiusMiles = 10;
  static const double defaultRadiusMiles = 6;

  final String selectedLocation;
  final double radiusMiles;
  final bool showOpenOnly;
  final MatchSortOption sortOption;
  final MatchDateFilter dateFilter;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;
  bool get usesCurrentLocation => selectedLocation == defaultLocation;

  factory MatchFilters.defaults() {
    return const MatchFilters(
      selectedLocation: defaultLocation,
      radiusMiles: defaultRadiusMiles,
      showOpenOnly: true,
      sortOption: MatchSortOption.distance,
      dateFilter: MatchDateFilter.any,
    );
  }

  MatchFilters copyWith({
    String? selectedLocation,
    double? radiusMiles,
    bool? showOpenOnly,
    MatchSortOption? sortOption,
    MatchDateFilter? dateFilter,
    double? latitude,
    double? longitude,
    bool clearCoordinates = false,
  }) {
    return MatchFilters(
      selectedLocation: selectedLocation ?? this.selectedLocation,
      radiusMiles: radiusMiles ?? this.radiusMiles,
      showOpenOnly: showOpenOnly ?? this.showOpenOnly,
      sortOption: sortOption ?? this.sortOption,
      dateFilter: dateFilter ?? this.dateFilter,
      latitude: clearCoordinates ? null : latitude ?? this.latitude,
      longitude: clearCoordinates ? null : longitude ?? this.longitude,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MatchFilters &&
        other.selectedLocation == selectedLocation &&
        other.radiusMiles == radiusMiles &&
        other.showOpenOnly == showOpenOnly &&
        other.sortOption == sortOption &&
        other.dateFilter == dateFilter &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(
    selectedLocation,
    radiusMiles,
    showOpenOnly,
    sortOption,
    dateFilter,
    latitude,
    longitude,
  );
}
