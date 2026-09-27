enum MatchSortOption { distance }

class MatchFilters {
  const MatchFilters({
    required this.selectedLocation,
    required this.radiusMiles,
    required this.showOpenOnly,
    required this.sortOption,
  });

  static const String defaultLocation = 'Current Location';
  static const double minRadiusMiles = 1;
  static const double maxRadiusMiles = 10;
  static const double defaultRadiusMiles = 6;

  final String selectedLocation;
  final double radiusMiles;
  final bool showOpenOnly;
  final MatchSortOption sortOption;

  factory MatchFilters.defaults() {
    return const MatchFilters(
      selectedLocation: defaultLocation,
      radiusMiles: defaultRadiusMiles,
      showOpenOnly: true,
      sortOption: MatchSortOption.distance,
    );
  }

  MatchFilters copyWith({
    String? selectedLocation,
    double? radiusMiles,
    bool? showOpenOnly,
    MatchSortOption? sortOption,
  }) {
    return MatchFilters(
      selectedLocation: selectedLocation ?? this.selectedLocation,
      radiusMiles: radiusMiles ?? this.radiusMiles,
      showOpenOnly: showOpenOnly ?? this.showOpenOnly,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MatchFilters &&
        other.selectedLocation == selectedLocation &&
        other.radiusMiles == radiusMiles &&
        other.showOpenOnly == showOpenOnly &&
        other.sortOption == sortOption;
  }

  @override
  int get hashCode =>
      Object.hash(selectedLocation, radiusMiles, showOpenOnly, sortOption);
}
