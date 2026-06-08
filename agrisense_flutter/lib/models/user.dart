class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String role;
  final String phone;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.role,
    required this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      role: json['role'],
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'role': role,
      'phone': phone,
    };
  }
}
