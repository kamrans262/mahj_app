import 'package:flutter/material.dart';

import '../../domain/home_match.dart';

class MatchStatusBadge extends StatelessWidget {
  const MatchStatusBadge({required this.status, super.key});

  final MatchStatus status;

  @override
  Widget build(BuildContext context) {
    final visual = switch (status) {
      MatchStatus.open => const _StatusVisual(
        label: 'Open',
        foreground: Color(0xFF2E9B4F),
        background: Color(0xFFDDF3E3),
      ),
      MatchStatus.confirmed => const _StatusVisual(
        label: 'Confirmed',
        foreground: Color(0xFF3D7BF3),
        background: Color(0xFFDCE9FF),
      ),
      MatchStatus.cancelled => const _StatusVisual(
        label: 'Cancelled',
        foreground: Color(0xFFE33A3A),
        background: Color(0xFFFFDDDD),
      ),
      MatchStatus.full => const _StatusVisual(
        label: 'Full',
        foreground: Color(0xFFD88700),
        background: Color(0xFFFFEBC7),
      ),
      MatchStatus.completed => const _StatusVisual(
        label: 'Completed',
        foreground: Color(0xFF2E9B4F),
        background: Color(0xFFDDF3E3),
      ),
    };

    return Container(
      constraints: const BoxConstraints(minHeight: 20, minWidth: 40),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: visual.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        visual.label,
        maxLines: 1,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          height: 1,
          color: visual.foreground,
        ),
      ),
    );
  }
}

class _StatusVisual {
  const _StatusVisual({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;
}
