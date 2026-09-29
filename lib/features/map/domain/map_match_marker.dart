import '../../home/domain/home_match.dart';

class MapMatchMarker {
  const MapMatchMarker({
    required this.match,
    required this.normalizedX,
    required this.normalizedY,
    required this.distanceMiles,
    this.playerAvatarAssets = const [],
  }) : assert(normalizedX >= 0 && normalizedX <= 1),
       assert(normalizedY >= 0 && normalizedY <= 1),
       assert(distanceMiles >= 0);

  final HomeMatch match;
  final double normalizedX;
  final double normalizedY;
  final double distanceMiles;
  final List<String> playerAvatarAssets;
}
