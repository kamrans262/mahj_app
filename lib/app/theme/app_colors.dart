import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFFEC5D01);
  static const Color background = Color(0xFFFFFFFF);

  static const Color heading = Color(0xFF0D1328);
  static const Color textPrimary = heading;
  static const Color textSecondary = Color(0xFF667085);
  static const Color textMuted = Color(0xFFB7BED3);
  static const Color notificationIconSurface = Color(0xFFFBDFCC);

  static const Color border = Color(0xFFF1E8E2);
  static const Color divider = Color(0xFFF2F4F7);
  static const Color disabled = Color(0xFFD0D5DD);
  static const Color error = Color(0xFFD92D20);
  static const Color destructive = Color(0xFFEF4444);

  static const Color navigationButtonBackground = Color(0xFFFFFFFF);
  static const Color navigationButtonBorder = Color(0x33F1D5C1);
  static const Color navigationButtonShadow = Color(0x05000000);

  static const Color authGlow = Color(0x14EC5D01);
  static const Color authSurface = Color(0xFFFFFFFF);

  static const Color cardShadow = Color(0x0D000005);

  // Exact solid shared reusable surface requested for Mahj controls/cards.
  static const Color nearbyMatchCardSurface = Color(0xFFFFFFFF);
  static const Color subtleSurface = Color(0xFFFFFFFF);

  // Neutral border/shadow for #FFFFFF controls. These deliberately avoid the
  // older peach/orange-tinted border around light surfaces.
  static const Color controlBorder = Color(0x1A0D1328);
  static const Color controlShadow = Color(0x080D1328);
  static const Color controlPressedOverlay = Color(0x080D1328);

  static const Color filterSliderInactive = Color(0x61EC5D01);
  static const Color subtleBorder = Color(0x33F1D5C1);
  static const Color subtleShadow = Color(0x0D000005);

  static const Color invitationHeroSurface = Color(0x66E2F1E3);

  static const Color matchSuccess = Color(0xFF319A3B);
  static const Color matchSuccessCardSurface = Color(0xFFFFFFFF);
  static const Color matchSuccessBackdrop = Color.fromRGBO(0, 0, 0, 0.60);

  // Shared confirmation modal treatment.
  static const Color confirmationBackdrop = Color(0x80000000);
  static const Color confirmationDialogShadow = Color(0x0D7C4DFF);
  static const Color dialogInputSurface = Color(0xFFFFFFFF);
  static const Color subscriptionActiveBadge = Color(0xFFFCE7D9);
}
