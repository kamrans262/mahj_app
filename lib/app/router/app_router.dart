import 'package:flutter/material.dart';

import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/home/presentation/all_nearby_matches_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/matches/presentation/create_match_screen.dart';
import '../../features/premium/presentation/premium_plan_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String premiumPlan = '/premium-plan';
  static const String home = '/home';
  static const String nearbyMatches = '/nearby-matches';
  static const String createMatch = '/create-match';
}

abstract final class AppRouter {
  static Map<String, WidgetBuilder> get routes => {
    AppRoutes.splash: (_) => const SplashScreen(),
    AppRoutes.login: (context) => LoginScreen(
      onLogin: (email, password) async {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      },
      onForgotPassword: () {
        Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
      },
      onSignUp: () {
        Navigator.of(context).pushNamed(AppRoutes.signUp);
      },
    ),
    AppRoutes.signUp: (context) => SignUpScreen(
      onSignUp: (fullName, email, password) async {
        Navigator.of(context).pushNamed(AppRoutes.premiumPlan);
      },
      onBack: () {
        Navigator.of(context).maybePop();
      },
      onLogin: () {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        } else {
          navigator.pushReplacementNamed(AppRoutes.login);
        }
      },
    ),
    AppRoutes.forgotPassword: (context) => ForgotPasswordScreen(
      onBack: () {
        Navigator.of(context).maybePop();
      },
      onBackToLogin: () {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        } else {
          navigator.pushReplacementNamed(AppRoutes.login);
        }
      },
    ),
    AppRoutes.premiumPlan: (context) => PremiumPlanScreen(
      onBack: () {
        Navigator.of(context).maybePop();
      },
    ),
    AppRoutes.home: (context) => HomeScreen(
      onNearbyViewAll: () {
        Navigator.of(context).pushNamed(AppRoutes.nearbyMatches);
      },
      onCreateMatch: () {
        Navigator.of(context).pushNamed(AppRoutes.createMatch);
      },
    ),
    AppRoutes.nearbyMatches: (context) => AllNearbyMatchesScreen(
      onBack: () {
        Navigator.of(context).maybePop();
      },
      onCreateMatch: () {
        Navigator.of(context).pushNamed(AppRoutes.createMatch);
      },
    ),
    AppRoutes.createMatch: (context) => CreateMatchScreen(
      onBack: () {
        Navigator.of(context).maybePop();
      },
      onCancel: () {
        Navigator.of(context).maybePop();
      },
    ),
  };
}
