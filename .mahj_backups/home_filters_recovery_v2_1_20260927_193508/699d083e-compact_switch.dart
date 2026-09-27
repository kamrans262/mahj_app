import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class CompactSwitch extends StatelessWidget {
  const CompactSwitch({
    required this.value,
    required this.onChanged,
    super.key,
    this.semanticsLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: value,
      label: semanticsLabel,
      child: InkResponse(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        radius: 24,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              width: 22,
              height: 12,
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: value
                    ? AppColors.primary
                    : AppColors.textSecondary.withValues(alpha: 0.30),
                borderRadius: BorderRadius.circular(999),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
