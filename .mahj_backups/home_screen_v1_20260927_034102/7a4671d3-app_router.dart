import 'package:flutter/material.dart';

import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/premium/presentation/premium_plan_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String premiumPlan = '/premium-plan';
}

abstract final class AppRouter {
  static Map<String, WidgetBuilder> get routes => {
    AppRoutes.splash: (_) => const SplashScreen(),
    AppRoutes.login: (context) => LoginScreen(
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
  };
}
