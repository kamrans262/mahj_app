import 'package:flutter/material.dart';

import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/home/domain/home_match.dart';
import '../../features/home/presentation/all_nearby_matches_screen.dart';
import '../../features/matches/presentation/create_match_screen.dart';
import '../../features/matches/presentation/match_details_screen.dart';
import '../../features/navigation/presentation/main_navigation_shell.dart';
import '../../features/premium/presentation/premium_plan_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String premiumPlan = '/premium-plan';
  static const String home = '/home';
  static const String map = '/map';
  static const String nearbyMatches = '/nearby-matches';
  static const String createMatch = '/create-match';
  static const String matchDetails = '/match-details';
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
    AppRoutes.home: (context) => _mainShell(context),
    AppRoutes.map: (context) => _mainShell(context, initialIndex: 1),
    AppRoutes.nearbyMatches: (context) => AllNearbyMatchesScreen(
      onBack: () {
        Navigator.of(context).maybePop();
      },
      onMatchTap: (match) {
        _openMatchDetails(context, match);
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

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name != AppRoutes.matchDetails) {
      return null;
    }

    final match = settings.arguments;
    if (match is! HomeMatch) {
      return null;
    }

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => MatchDetailsScreen(
        match: match,
        onBack: () => Navigator.of(context).maybePop(),
      ),
    );
  }

  static MainNavigationShell _mainShell(
    BuildContext context, {
    int initialIndex = 0,
  }) {
    return MainNavigationShell(
      initialIndex: initialIndex,
      onNearbyViewAll: () {
        Navigator.of(context).pushNamed(AppRoutes.nearbyMatches);
      },
      onCreateMatch: () {
        Navigator.of(context).pushNamed(AppRoutes.createMatch);
      },
      onMatchTap: (match) {
        _openMatchDetails(context, match);
      },
    );
  }

  static void _openMatchDetails(BuildContext context, HomeMatch match) {
    Navigator.of(context).pushNamed(AppRoutes.matchDetails, arguments: match);
  }
}
