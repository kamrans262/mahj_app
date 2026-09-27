import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../home/domain/home_match.dart';
import '../../home/presentation/widgets/match_card.dart';

class MatchDetailsScreen extends StatelessWidget {
  const MatchDetailsScreen({required this.match, super.key, this.onBack});

  final HomeMatch match;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.lg,
                AppSpacing.pageHorizontal,
                0,
              ),
              child: AppCenteredPageHeader(
                title: 'Match Details',
                onBack: onBack ?? () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
                child: MatchCard(match: match),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
