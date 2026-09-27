import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_asset_icon.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_button.dart';
import '../../auth/presentation/widgets/auth_background.dart';

class PremiumPlanScreen extends StatefulWidget {
  const PremiumPlanScreen({
    super.key,
    this.isLoading = false,
    this.onBack,
    this.onStartFreeTrial,
    this.onTermsOfService,
    this.onPrivacyPolicy,
  });

  final bool isLoading;
  final VoidCallback? onBack;
  final Future<void> Function()? onStartFreeTrial;
  final VoidCallback? onTermsOfService;
  final VoidCallback? onPrivacyPolicy;

  @override
  State<PremiumPlanScreen> createState() => _PremiumPlanScreenState();
}

class _PremiumPlanScreenState extends State<PremiumPlanScreen> {
  bool _isSubmitting = false;

  bool get _isBusy => widget.isLoading || _isSubmitting;

  Future<void> _startFreeTrial() async {
    if (_isBusy) {
      return;
    }

    final callback = widget.onStartFreeTrial;
    if (callback == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await callback();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableHeight = math.max(0.0, constraints.maxHeight);
              final flexibleActionGap = (availableHeight - 560)
                  .clamp(
                    AppSpacing.premiumFlexibleGapMin,
                    AppSpacing.premiumFlexibleGapMax,
                  )
                  .toDouble();

              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: availableHeight),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Padding(
                        // Page alignment is intentionally applied exactly once.
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.pageHorizontal,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: AppSpacing.lg),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: AppBackButton(
                                key: const ValueKey('premium-back-button'),
                                onPressed: _isBusy ? null : widget.onBack,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            const Center(child: _PremiumCrownBadge()),
                            const SizedBox(height: AppSpacing.lg),
                            const Text(
                              'Start your 14 day free trial',
                              key: ValueKey('premium-heading'),
                              textAlign: TextAlign.center,
                              style: AppTypography.authHeading,
                            ),
                            const SizedBox(
                              height: AppSpacing.premiumSectionGap,
                            ),
                            const _PremiumFeatureRow(
                              key: ValueKey('premium-feature-1'),
                              iconKey: ValueKey('premium-approve-1'),
                              text: 'See available matches close to you',
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const _PremiumFeatureRow(
                              key: ValueKey('premium-feature-2'),
                              iconKey: ValueKey('premium-approve-2'),
                              text: 'Create and join matches',
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const _PremiumFeatureRow(
                              key: ValueKey('premium-feature-3'),
                              iconKey: ValueKey('premium-approve-3'),
                              text: 'Chat with Players',
                            ),
                            const SizedBox(
                              height: AppSpacing.premiumSectionGap,
                            ),
                            const _MonthlyPlanCard(),
                            SizedBox(height: flexibleActionGap),
                            AppButton.primary(
                              key: const ValueKey('start-free-trial-button'),
                              label: 'Start Free Trial',
                              onPressed: _startFreeTrial,
                              isLoading: _isBusy,
                              isEnabled: !_isBusy,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const Text(
                              'You won’t be charged until the trial ends',
                              key: ValueKey('premium-trial-notice'),
                              textAlign: TextAlign.center,
                              style: AppTypography.action14,
                            ),
                            const SizedBox(height: AppSpacing.premiumLegalGap),
                            _PremiumLegalFooter(
                              onTermsOfService: widget.onTermsOfService,
                              onPrivacyPolicy: widget.onPrivacyPolicy,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PremiumCrownBadge extends StatelessWidget {
  const _PremiumCrownBadge();

  static const double _badgeSize = 48;
  static const double _iconSize = 24;

  @override
  Widget build(BuildContext context) {
    if (AppAssets.premiumCrownIncludesBadge) {
      return const AppAssetIcon(
        key: ValueKey('premium-crown-badge'),
        assetPath: AppAssets.premiumCrownIcon,
        size: _badgeSize,
      );
    }

    return Container(
      key: const ValueKey('premium-crown-badge'),
      width: _badgeSize,
      height: _badgeSize,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      alignment: Alignment.center,
      child: const AppAssetIcon(
        assetPath: AppAssets.premiumCrownIcon,
        size: _iconSize,
      ),
    );
  }
}

class _PremiumFeatureRow extends StatelessWidget {
  const _PremiumFeatureRow({
    required this.text,
    required this.iconKey,
    super.key,
  });

  final String text;
  final Key iconKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppAssetIcon(key: iconKey, assetPath: AppAssets.approveIcon, size: 24),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: AppTypography.body16)),
      ],
    );
  }
}

class _MonthlyPlanCard extends StatelessWidget {
  const _MonthlyPlanCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('monthly-plan-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.authSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.navigationButtonBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Monthly Plan', style: AppTypography.title18),
                SizedBox(height: AppSpacing.micro),
                Text('No charges for 14 days', style: AppTypography.body14),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Text(
            r'$0.00',
            key: ValueKey('premium-price'),
            maxLines: 1,
            softWrap: false,
            style: AppTypography.title18,
          ),
        ],
      ),
    );
  }
}

class _PremiumLegalFooter extends StatefulWidget {
  const _PremiumLegalFooter({this.onTermsOfService, this.onPrivacyPolicy});

  final VoidCallback? onTermsOfService;
  final VoidCallback? onPrivacyPolicy;

  @override
  State<_PremiumLegalFooter> createState() => _PremiumLegalFooterState();
}

class _PremiumLegalFooterState extends State<_PremiumLegalFooter> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer();
    _privacyRecognizer = TapGestureRecognizer();
    _syncRecognizers();
  }

  @override
  void didUpdateWidget(covariant _PremiumLegalFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRecognizers();
  }

  void _syncRecognizers() {
    _termsRecognizer.onTap = widget.onTermsOfService;
    _privacyRecognizer.onTap = widget.onPrivacyPolicy;
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: AppTypography.legal12,
        children: [
          const TextSpan(text: 'By continuing, you agree to our '),
          TextSpan(
            text: 'terms of services',
            style: AppTypography.legalLink12,
            recognizer: _termsRecognizer,
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'privacy policy',
            style: AppTypography.legalLink12,
            recognizer: _privacyRecognizer,
          ),
        ],
      ),
      key: const ValueKey('premium-legal-footer'),
      textAlign: TextAlign.center,
    );
  }
}
