enum OtpPurpose {
  registration,
  passwordReset;

  String get apiValue {
    switch (this) {
      case OtpPurpose.registration:
        return 'registration';
      case OtpPurpose.passwordReset:
        return 'password_reset';
    }
  }
}

class OtpRouteArgs {
  const OtpRouteArgs({
    required this.email,
    required this.purpose,
  });

  final String email;
  final OtpPurpose purpose;
}

class ResetPasswordRouteArgs {
  const ResetPasswordRouteArgs({
    required this.email,
    required this.resetToken,
  });

  final String email;
  final String resetToken;
}
