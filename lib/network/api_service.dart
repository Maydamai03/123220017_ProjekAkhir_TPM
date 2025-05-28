import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:projek_akhir_tpm/models/product_model.dart';
import '../models/user_model.dart';

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

    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Login gagal");
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
}
