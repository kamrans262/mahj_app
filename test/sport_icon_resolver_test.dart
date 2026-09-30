import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/app_assets.dart';
import 'package:mahj_app/features/home/presentation/widgets/sport_icon.dart';

void main() {
  test('sport icon keys resolve to related SVG assets', () {
    expect(
      SportIconResolver.assetForKey('football'),
      AppAssets.americanFootballIcon,
    );
    expect(
      SportIconResolver.assetForKey('basketball'),
      AppAssets.basketballIcon,
    );
    expect(
      SportIconResolver.assetForKey('soccer'),
      AppAssets.homeFootballIcon,
    );
    expect(SportIconResolver.assetForKey('baseball'), AppAssets.baseballIcon);
    expect(SportIconResolver.assetForKey('tennis'), AppAssets.tennisIcon);
    expect(
      SportIconResolver.assetForKey('unknown-sport'),
      AppAssets.genericSportIcon,
    );
  });
}
