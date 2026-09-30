import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';
import '../../../app/router/app_router.dart';
import '../../../core/widgets/app_loader.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.navigateToLogin = true,
    this.duration = const Duration(milliseconds: 1500),
    this.onResolveRoute,
  });

  final bool navigateToLogin;
  final Duration duration;
  final Future<String> Function()? onResolveRoute;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _logoToLoaderGap = 35.0;
  static const _logoWidthFactor = 0.52;
  static const _minimumLogoWidth = 180.0;
  static const _maximumLogoWidth = 280.0;

  @override
  void initState() {
    super.initState();
    if (widget.navigateToLogin) {
      _openNextRoute();
    }
  }

  Future<void> _openNextRoute() async {
    if (!mounted) return;

    final routeFuture =
        widget.onResolveRoute?.call() ??
        Future<String>.value(AppRoutes.login);

    await Future<void>.delayed(widget.duration);
    final route = await routeFuture;
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final logoWidth = (constraints.maxWidth * _logoWidthFactor)
                  .clamp(_minimumLogoWidth, _maximumLogoWidth)
                  .toDouble();

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    AppAssets.splashLogo,
                    key: const ValueKey('splash-logo'),
                    width: logoWidth,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                  const SizedBox(height: _logoToLoaderGap),
                  const AppLoader(key: ValueKey('splash-loader')),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
