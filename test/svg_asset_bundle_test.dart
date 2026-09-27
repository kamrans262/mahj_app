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
    ];

    for (final asset in assets) {
      final source = await rootBundle.loadString(asset);
      expect(source.trim(), isNotEmpty, reason: asset);
      expect(source.toLowerCase(), contains('<svg'), reason: asset);
    }
  });
}
