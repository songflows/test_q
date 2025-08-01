class User {
  final int id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final String authProvider;
  final bool isVerified;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.avatarUrl,
    required this.authProvider,
    required this.isVerified,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      authProvider: json['auth_provider'],
      isVerified: json['is_verified'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'auth_provider': authProvider,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? email,
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? authProvider,
    bool? isVerified,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      authProvider: authProvider ?? this.authProvider,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}