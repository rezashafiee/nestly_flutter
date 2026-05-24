class UserProfile {
  const UserProfile({required this.name, required this.email});

  factory UserProfile.fromJson(Map<String, Object?> json) {
    return UserProfile(
      name: json['name']?.toString() ?? 'Nestly User',
      email: json['email']?.toString() ?? '',
    );
  }

  final String name;
  final String email;

  Map<String, Object?> toJson() {
    return {'name': name, 'email': email};
  }
}
