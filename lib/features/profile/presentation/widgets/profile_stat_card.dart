import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_surface_container.dart';

class ProfileStatCard extends StatelessWidget {
  const ProfileStatCard({required this.label, required this.value, super.key});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceContainer(
      minHeight: 84,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.homeMeta12,
          ),
          const SizedBox(height: AppSpacing.micro),
          Text(
            '$value',
            textAlign: TextAlign.center,
            style: AppTypography.homeMatchTitle16,
          ),
        ],
      ),
    );
  }
}
