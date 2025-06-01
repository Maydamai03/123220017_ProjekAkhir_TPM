import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive
import 'package:projek_akhir_tpm/views/home_page.dart';
import 'package:projek_akhir_tpm/views/login_page.dart';
import 'package:projek_akhir_tpm/utils/session_manager.dart';
import 'package:projek_akhir_tpm/models/cart_item_model.dart'; // Import CartItem
import 'package:projek_akhir_tpm/models/product_model.dart'; // Import ProductModel (untuk adapter)
import 'package:projek_akhir_tpm/models/wishlist_item_model.dart'; // <<< Import WishlistItem



void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Pastikan Flutter binding diinisialisasi

  // --- Inisialisasi Hive dan Register Adapters ---
  await Hive.initFlutter();
  Hive.registerAdapter(CartItemAdapter()); // Daftar adapter CartItem (Generated)
  Hive.registerAdapter(ProductModelAdapter()); // Daftar adapter ProductModel (Generated)
  Hive.registerAdapter(WishlistItemAdapter()); // <<< DAFTARKAN WISHLIST ADAPTER


  // ------------------------------------------------

  // Cek status login
  bool isLoggedIn = await SessionManager.isLoggedIn();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toko Aksesoris',
      debugShowCheckedModeBanner: false, // Untuk menyembunyikan banner "DEBUG"
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: isLoggedIn ? const HomePage() : const LoginPage(),
    );
  }
}