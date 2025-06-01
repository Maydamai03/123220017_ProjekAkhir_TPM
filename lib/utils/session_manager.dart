import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class SessionManager {
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _userDataKey = 'userData';
  static const String _profileImagePathKey = 'profileImagePath';

  static Future<void> saveLogin(UserModel user) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    // Simpan UserModel sebagai JSON string
    // Pastikan user.toJson() sekarang menyertakan 'token'
    await prefs.setString(_userDataKey, jsonEncode(user.toJson()));
  }

  static Future<bool> isLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<UserModel?> getLoggedInUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      return UserModel.fromJson(jsonDecode(userDataString));
    }
    return null;
  }

  static Future<int?> getLoggedInUserId() async {
    final UserModel? user = await getLoggedInUser();
    return user?.userid;
  }

  static Future<void> saveProfileImagePath(String path) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImagePathKey, path);
  }

  static Future<String?> getProfileImagePath() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileImagePathKey);
  }

  static Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userDataKey);
    await prefs
        .remove(_profileImagePathKey);
  }

// Simpan gambar base64 berdasarkan userId
static Future<void> saveProfileImageBase64(String imageBase64, int userId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('profile_image_base64_$userId', imageBase64);
}

// Ambil gambar base64 berdasarkan userId
static Future<String?> getProfileImageBase64(int userId) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('profile_image_base64_$userId');
}


}

// Tambahkan metode toJson() di UserModel agar bisa di-encode ke JSON
extension UserModelExtension on UserModel {
  Map<String, dynamic> toJson() {
    return {
      'token': token, // <<< TAMBAHKAN BARIS INI!
      'id': userid,
      'email': email,
      'name': name,
      'role': role,
    };
  }
}