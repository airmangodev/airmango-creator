
class AppUser {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    DateTime? createdAt,
    this.lastLoginAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photo_url'],
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now() 
          : DateTime.now(),
      lastLoginAt: map['last_login_at'] != null 
          ? DateTime.tryParse(map['last_login_at']) 
          : null,
    );
  }
}
