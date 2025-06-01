import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:projek_akhir_tpm/models/product_model.dart';
import '../models/user_model.dart';
import '../models/order_model.dart'; // <<< PENTING: Import OrderModel di sini

class ApiService {
  final String baseUrl =
      "https://aksesoris-api-17-296685597625.us-central1.run.app";

// LOGIN METHOD
  Future<UserModel> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    print("Response Login: ${response.body}");

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? "Login gagal");
    }
  }

// REGISTER METHOD
  Future<UserModel> register(String name, String email, String password, String role) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
        "role": role,
      }),
    );

    print("Response Register: ${response.body}");

    if (response.statusCode == 201) {
      // Backend Register hanya mengembalikan data user TANPA token.
      // Kita perlu membuat objek UserModel di sini.
      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      return UserModel(
        token: '', // Atau String.empty; di sini token kosong karena tidak ada dari register
        userid: responseBody['id'] as int,
        email: responseBody['email'] as String,
        name: responseBody['name'] as String,
        role: responseBody['role'] as String,
        profileImageBase64: null, // Asumsi tidak ada dari respons register
      );
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? "Registrasi gagal");
    }
  }

//GET PRODUCT METHOD
  Future<List<ProductModel>> getProducts() async {
    final response = await http.get(Uri.parse("$baseUrl/products"));

    if (response.statusCode == 200) {
      List jsonList = jsonDecode(response.body);
      return jsonList.map((json) => ProductModel.fromJson(json)).toList();
    } else {
      throw Exception("Gagal mengambil data produk");
    }
  }

  // --- METHOD BARU UNTUK ORDER ---

  /// Mengirim pesanan baru ke backend.
  /// Membutuhkan token otentikasi.
  Future<OrderModel> createOrder(String token, OrderModel order) async {
    final response = await http.post(
      Uri.parse("$baseUrl/orders"), // Endpoint untuk membuat pesanan
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", // Kirim token otentikasi
      },
      body: jsonEncode(order.toJson()), // Menggunakan toJson dari OrderModel
    );

    print("Response Create Order: ${response.body}");

    if (response.statusCode == 201) { // 201 Created
      return OrderModel.fromJson(jsonDecode(response.body));
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? "Gagal membuat pesanan di backend");
    }
  }

  /// Mengambil daftar pesanan dari backend untuk user yang login.
  /// Membutuhkan token otentikasi.
  Future<List<OrderModel>> getOrders(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/orders"), // Endpoint untuk mendapatkan semua pesanan
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print("Response Get Orders: ${response.body}");

    if (response.statusCode == 200) { // 200 OK
      final List jsonList = jsonDecode(response.body);
      return jsonList.map((json) => OrderModel.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? "Gagal mengambil pesanan dari backend");
    }
  }
}