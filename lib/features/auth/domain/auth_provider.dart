enum AuthProvider {
  google,
  apple,
  emailPassword,
  phone,
  anonymous,
  unknown,
}

extension AuthProviderX on AuthProvider {
  String get short {
    switch (this) {
      case AuthProvider.google:
        return 'google';
      case AuthProvider.apple:
        return 'apple';
      case AuthProvider.emailPassword:
        return 'password';
      case AuthProvider.phone:
        return 'phone';
      case AuthProvider.anonymous:
        return 'anonymous';
      case AuthProvider.unknown:
        return 'unknown';
    }
  }

  String get providerId {
    switch (this) {
      case AuthProvider.google:
        return 'google.com';
      case AuthProvider.apple:
        return 'apple.com';
      case AuthProvider.emailPassword:
        return 'password';
      case AuthProvider.phone:
        return 'phone';
      case AuthProvider.anonymous:
        return 'anonymous';
      case AuthProvider.unknown:
        return 'unknown';
    }
  }

  static AuthProvider fromProviderId(String? id) {
    switch (id) {
      case 'google.com':
        return AuthProvider.google;
      case 'apple.com':
        return AuthProvider.apple;
      case 'password':
        return AuthProvider.emailPassword;
      case 'phone':
        return AuthProvider.phone;
      case 'anonymous':
        return AuthProvider.anonymous;
      default:
        return AuthProvider.unknown;
    }
  }

  static AuthProvider fromShort(String? value) {
    switch (value) {
      case 'google':
        return AuthProvider.google;
      case 'apple':
        return AuthProvider.apple;
      case 'password':
        return AuthProvider.emailPassword;
      case 'phone':
        return AuthProvider.phone;
      case 'anonymous':
        return AuthProvider.anonymous;
      default:
        return AuthProvider.unknown;
    }
  }
}
