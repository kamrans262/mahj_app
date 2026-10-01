import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_surface_container.dart';
import '../../domain/subscription_plan.dart';

class SubscriptionPlanCard extends StatelessWidget {
  const SubscriptionPlanCard({
    required this.plan,
    super.key,
    this.isSelected = false,
    this.onTap,
  });

  final SubscriptionPlan plan;
  final bool isSelected;
  final VoidCallback? onTap;

  bool get _highlighted => plan.isCurrent || isSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      selected: isSelected || plan.isCurrent,
      label: plan.isCurrent ? '${plan.name}, current plan' : plan.name,
      child: AppSurfaceContainer(
        key: ValueKey('subscription-plan-${plan.id}'),
        minHeight: 0,
        padding: const EdgeInsets.all(AppSpacing.lg),
        backgroundColor: AppColors.background,
        borderColor: _highlighted ? AppColors.primary : AppColors.controlBorder,
        onTap: onTap,
        child: plan.isCurrent
            ? _CurrentPlanContent(plan: plan)
            : _AvailablePlanContent(plan: plan),
      ),
    );
  }
}

class _CurrentPlanContent extends StatelessWidget {
  const _CurrentPlanContent({required this.plan});

  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.name,
                softWrap: true,
                style: AppTypography.homeMatchTitle18,
              ),
              if (plan.renewalText != null && plan.renewalText!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  plan.renewalText!,
                  softWrap: true,
                  style: AppTypography.homeMeta14,
                ),
              ],
            ],
          ),
        ),
        if (plan.statusText != null && plan.statusText!.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            key: const ValueKey('subscription-status-badge'),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.micro,
            ),
            decoration: BoxDecoration(
              color: AppColors.subscriptionActiveBadge,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(plan.statusText!, style: AppTypography.homeMeta12),
          ),
        ],
      ],
    );
  }
}

class _AvailablePlanContent extends StatelessWidget {
  const _AvailablePlanContent({required this.plan});

  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.name,
                softWrap: true,
                style: AppTypography.homeMatchTitle18,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                plan.description,
                softWrap: true,
                style: AppTypography.homeMeta14,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              plan.priceLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppTypography.homeGreeting,
            ),
          ),
        ),
      ],
    );
  }
}
