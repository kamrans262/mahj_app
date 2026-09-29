import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/success_celebration.dart';
import '../../../home/domain/home_match.dart';
import '../../../home/presentation/home_date_time_formatter.dart';
import '../../../home/presentation/widgets/match_card.dart';

class MatchCreatedOverlay extends StatelessWidget {
  const MatchCreatedOverlay({
    required this.match,
    super.key,
    this.onInvitePlayers,
    this.onBackHome,
    this.onViewMatch,
  });

  final HomeMatch match;
  final ValueChanged<HomeMatch>? onInvitePlayers;
  final ValueChanged<HomeMatch>? onBackHome;
  final ValueChanged<HomeMatch>? onViewMatch;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final stackSecondaryActions =
        textScale > 1.35 || MediaQuery.sizeOf(context).width < 350;

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ModalBarrier(
              dismissible: false,
              color: AppColors.matchSuccessBackdrop,
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageHorizontal,
                      vertical: AppSpacing.lg,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 2 * AppSpacing.lg)
                            .clamp(0.0, double.infinity),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Center(child: SuccessCelebration()),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'Match Created',
                              textAlign: TextAlign.center,
                              style: AppTypography.homeGreeting.copyWith(
                                color: AppColors.heading.withValues(
                                  alpha: 0.88,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'The match has been created successfully',
                              textAlign: TextAlign.center,
                              style: AppTypography.homeMeta12.copyWith(
                                color: AppColors.heading,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            MatchCard(
                              match: match,
                              showStatus: false,
                              showPlayerCount: false,
                              subtitle: HomeDateTimeFormatter.featuredSchedule(
                                match.startsAt,
                              ),
                              surfaceColor: AppColors.matchSuccessCardSurface,
                              titleStyle: AppTypography.homeMatchTitle18,
                              sportIconSize: 40,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            if (stackSecondaryActions)
                              Column(
                                children: [
                                  AppButton.secondary(
                                    label: 'Invite Players',
                                    onPressed: onInvitePlayers == null
                                        ? null
                                        : () => onInvitePlayers!(match),
                                    textStyle: AppTypography
                                        .matchSuccessSecondaryButton,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  AppButton.secondary(
                                    label: 'Back home',
                                    onPressed: onBackHome == null
                                        ? null
                                        : () => onBackHome!(match),
                                    textStyle: AppTypography
                                        .matchSuccessSecondaryButton,
                                  ),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  Expanded(
                                    child: AppButton.secondary(
                                      label: 'Invite Players',
                                      onPressed: onInvitePlayers == null
                                          ? null
                                          : () => onInvitePlayers!(match),
                                      textStyle: AppTypography
                                          .matchSuccessSecondaryButton,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: AppButton.secondary(
                                      label: 'Back home',
                                      onPressed: onBackHome == null
                                          ? null
                                          : () => onBackHome!(match),
                                      textStyle: AppTypography
                                          .matchSuccessSecondaryButton,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 16),
                            AppButton.primary(
                              label: 'View Match',
                              onPressed: onViewMatch == null
                                  ? null
                                  : () => onViewMatch!(match),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
