import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all project SVG icons are bundled and readable', () async {
    const assets = <String>[
      'assets/icons/apple.svg',
      'assets/icons/approve.svg',
      'assets/icons/crown.svg',
      'assets/icons/google.svg',
      'assets/icons/send.svg',
      'assets/icons/home.svg',
      'assets/icons/map.svg',
      'assets/icons/match.svg',
      'assets/icons/profile.svg',
      'assets/icons/basketball.svg',
      'assets/map_demo.svg',
      'assets/avatar_demo_1.svg',
      'assets/avatar_demo_2.svg',
      'assets/avatar_demo_3.svg',
    ];

    for (final asset in assets) {
      final source = await rootBundle.loadString(asset);
      expect(source.trim(), isNotEmpty, reason: asset);
      expect(source.toLowerCase(), contains('<svg'), reason: asset);
    }
  });
}
