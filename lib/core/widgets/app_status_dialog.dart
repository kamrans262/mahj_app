import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import 'app_modal_card.dart';

/// Reusable informational/status modal that shares the same card surface as
/// confirmation and report dialogs.
class AppStatusDialog extends StatefulWidget {
  const AppStatusDialog({
    required this.title,
    required this.message,
    required this.icon,
    super.key,
    this.autoDismissAfter = const Duration(milliseconds: 1800),
  });

  final String title;
  final String message;
  final Widget icon;
  final Duration? autoDismissAfter;

  @override
  State<AppStatusDialog> createState() => _AppStatusDialogState();
}

class _AppStatusDialogState extends State<AppStatusDialog> {
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    final duration = widget.autoDismissAfter;
    if (duration != null) {
      _dismissTimer = Timer(duration, () {
        if (mounted) {
          Navigator.of(context).maybePop();
        }
      });
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppModalCard(
      semanticLabel: widget.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: widget.icon),
          const SizedBox(height: AppSpacing.md),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: AppTypography.homeMatchTitle18,
          ),
          const SizedBox(height: AppSpacing.micro),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: AppTypography.homeMeta14,
          ),
        ],
      ),
    );
  }
}

/// Small circular status icon used by transient Match Details status dialogs.
class AppStatusCircleIcon extends StatelessWidget {
  const AppStatusCircleIcon({
    required this.backgroundColor,
    required this.icon,
    super.key,
    this.size = 32,
    this.iconSize = 22,
  });

  final Color backgroundColor;
  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: iconSize, color: Colors.white),
      ),
    );
  }
}
