class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.emailVerified = false,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String,
        emailVerified: json['email_verified'] as bool? ?? false,
      );

  final String id;
  final String email;
  final bool emailVerified;
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      );

  final String accessToken;
  final String refreshToken;
  final AuthUser user;
}

class AccountSession {
  const AccountSession({
    required this.id,
    required this.isCurrent,
    required this.createdAt,
    required this.expiresAt,
  });

  factory AccountSession.fromJson(Map<String, dynamic> json) => AccountSession(
        id: json['id'] as String,
        isCurrent: json['is_current'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        expiresAt: DateTime.parse(json['expires_at'] as String).toLocal(),
      );

  final String id;
  final bool isCurrent;
  final DateTime createdAt;
  final DateTime expiresAt;
}
