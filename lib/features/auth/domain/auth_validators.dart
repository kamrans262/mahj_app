abstract final class AuthValidators {
  static String? fullName(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Enter your full name';
    }
    return null;
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Enter your email address';
    }

    final atIndex = email.indexOf('@');
    final dotIndex = email.lastIndexOf('.');
    if (atIndex <= 0 ||
        dotIndex <= atIndex + 1 ||
        dotIndex >= email.length - 1) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Enter your password';
    }
    return null;
  }

  static String? newPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Enter your password';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final confirmation = value ?? '';
    if (confirmation.isEmpty) {
      return 'Confirm your password';
    }
    if (confirmation != password) {
      return 'Passwords do not match';
    }
    return null;
  }
}
