import 'package:flutter/material.dart';

/// Mahj's shared scroll behavior.
///
/// Flutter's Android stretch overscroll indicator inserts a transient
/// [Transform] render object around scrollables. During rapid route/tab
/// replacement that transform can become involved in framework
/// parent/semantics assertions on some Flutter/device combinations.
/// Mahj does not rely on stretch as part of its visual language, so we keep
/// the platform scrolling physics but render no overscroll decoration.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
