import 'package:flutter/material.dart';

import 'app_scroll_behavior.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class MahjApp extends StatelessWidget {
  const MahjApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppRouter.navigatorKey,
      title: 'Mahj Around Town',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      scrollBehavior: const AppScrollBehavior(),
      initialRoute: AppRoutes.splash,
      routes: AppRouter.routes,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
