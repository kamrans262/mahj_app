import '../../home/domain/home_match.dart';

class MapMatchMarker {
  const MapMatchMarker({
    required this.match,
    required this.normalizedX,
    required this.normalizedY,
    required this.distanceMiles,
    this.playerAvatarAssets = const [],
    this.playerAvatarUrls = const <String?>[],
  }) : assert(normalizedX >= 0 && normalizedX <= 1),
       assert(normalizedY >= 0 && normalizedY <= 1),
       assert(distanceMiles >= 0);

  factory MapMatchMarker.fromMatch(HomeMatch match) {
    return MapMatchMarker(
      match: match,
      normalizedX: 0.5,
      normalizedY: 0.5,
      distanceMiles: match.distanceMiles ?? 0,
      playerAvatarUrls: match.playerAvatarUrls,
    );
  }

  final HomeMatch match;
  final double normalizedX;
  final double normalizedY;
  final double distanceMiles;
  final List<String> playerAvatarAssets;
  final List<String?> playerAvatarUrls;

  bool get hasCoordinates => match.hasCoordinates;
}
