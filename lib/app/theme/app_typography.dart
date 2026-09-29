import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static const String fontFamily = 'Inter';

  static const TextStyle authHeading = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1,
    color: AppColors.heading,
  );

  static const TextStyle loginHeading = authHeading;

  static const TextStyle loginSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1,
    color: AppColors.textSecondary,
  );

  static const TextStyle body14 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle action14 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );

  static const TextStyle muted14 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  static const TextStyle socialButton = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.3,
    color: AppColors.textSecondary,
  );

  static const TextStyle primaryButton = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: Colors.white,
  );

  static const TextStyle dialogActionButton = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1,
    letterSpacing: -0.3,
    color: Colors.white,
  );

  static const TextStyle compactPrimaryButton = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1,
    letterSpacing: -0.3,
    color: Colors.white,
  );

  static const TextStyle matchSuccessSecondaryButton = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1,
    letterSpacing: -0.3,
    color: AppColors.primary,
  );

  static const TextStyle field = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.heading,
  );

  static const TextStyle fieldHint = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle successTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1,
    letterSpacing: -0.3,
    color: AppColors.heading,
  );

  static const TextStyle secondaryButton = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1,
    letterSpacing: -0.3,
    color: AppColors.primary,
  );

  static const TextStyle body16 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1,
    color: AppColors.textSecondary,
  );

  static const TextStyle title18 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1,
    color: AppColors.heading,
  );

  static const TextStyle legal12 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: AppColors.textSecondary,
  );

  static const TextStyle legalLink12 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: AppColors.primary,
  );

  static const TextStyle homeGreeting = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1,
    color: AppColors.heading,
  );

  static const TextStyle homeSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1,
    color: AppColors.textSecondary,
  );

  static const TextStyle homeSectionHeading = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1,
    color: AppColors.heading,
  );

  static const TextStyle homeAction12 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1,
    color: AppColors.primary,
  );

  static const TextStyle homeMatchTitle18 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1,
    letterSpacing: -0.3,
    color: AppColors.heading,
  );

  static const TextStyle homeMatchTitle16 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1,
    letterSpacing: -0.3,
    color: AppColors.heading,
  );

  static const TextStyle homeMeta14 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1,
    letterSpacing: -0.3,
    color: AppColors.textSecondary,
  );

  static const TextStyle homeMeta12 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1,
    letterSpacing: -0.3,
    color: AppColors.textSecondary,
  );

  static const TextStyle notificationTime10 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1,
    color: AppColors.textMuted,
  );
}
