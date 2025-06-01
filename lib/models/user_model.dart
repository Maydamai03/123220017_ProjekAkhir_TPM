class UserModel {
  final String token; // <<< JANGAN HAPUS INI! Ini penting untuk AUTENTIKASI.
  final String email;
  final String name;
  final String role;
  final int userid;
  final String? profileImageBase64; // Tambahkan ini sebagai properti opsional

  UserModel({
    required this.token, // <<< Ini wajib. Akan diisi dari respons LOGIN.
    required this.userid,
    required this.email,
    required this.name,
    required this.role,
    this.profileImageBase64, // <<< Ini opsional
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // Pastikan 'token' dibaca. Jika respons TIDAK memiliki 'token' (misal dari register),
      // maka Anda harus memberikan nilai default atau menangani di ApiService.
      // Dengan alur 'login setelah register', ini akan diisi dari respons LOGIN.
      token: (json['token'] ?? '')
          as String, // <<< Beri nilai default kosong jika null
      userid: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      profileImageBase64:
          json['profileImageBase64'] as String?, // Membaca profileImageBase64
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token, // <<< Pastikan ini disimpan ke JSON.
      'id': userid,
      'email': email,
      'name': name,
      'role': role,
      'profileImageBase64': profileImageBase64, // Menyimpan profileImageBase64
    };
  }

  // Tambahkan copyWith
  UserModel copyWith({
    String? token, // Sertakan token di copyWith
    String? email,
    String? name,
    String? role,
    int? userid,
    String? profileImageBase64,
  }) {
    return UserModel(
      token: token ?? this.token, // Menggunakan token yang baru atau yang lama
      userid: userid ?? this.userid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      profileImageBase64: profileImageBase64 ?? this.profileImageBase64,
    );
  }
}
