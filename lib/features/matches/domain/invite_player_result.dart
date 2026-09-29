class InvitePlayerResult {
  const InvitePlayerResult({
    required this.id,
    required this.searchText,
    required this.title,
    required this.startsAt,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.sportImageAsset,
    this.markerNormalizedX,
    this.markerNormalizedY,
  });

  final String id;

  /// Searchable backend/user label. It does not need to be the same value that
  /// is shown as the match/venue title in the Figma result card.
  final String searchText;
  final String title;
  final DateTime startsAt;
  final int currentPlayers;
  final int maxPlayers;
  final String sportImageAsset;
  final double? markerNormalizedX;
  final double? markerNormalizedY;

  bool get hasLocationPreview =>
      markerNormalizedX != null && markerNormalizedY != null;
}
