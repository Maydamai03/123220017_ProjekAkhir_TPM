class UserModel {
  final String token;
  final String email;
  final String name;
  final String role;
  final int userid;

  UserModel({
    required this.token,
    required this.userid,
    required this.email,
    required this.name,
    required this.role,

  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      token: json['token'],
      userid: json['id'],
      email: json['email'],
      name: json['name'],
      role: json['role'],
    );
  }
}
