class AuthToken {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final DateTime createdAt;

  AuthToken({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.createdAt,
  });

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      accessToken: json['access_token'],
      tokenType: json['token_type'] ?? 'bearer',
      expiresIn: json['expires_in'],
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isExpired {
    final expiryTime = createdAt.add(Duration(seconds: expiresIn));
    return DateTime.now().isAfter(expiryTime);
  }

  Duration get timeUntilExpiry {
    final expiryTime = createdAt.add(Duration(seconds: expiresIn));
    return expiryTime.difference(DateTime.now());
  }
}