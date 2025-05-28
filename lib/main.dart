// main.dart
import 'package:flutter/material.dart';
import 'package:projek_akhir_tpm/views/home_page.dart';
import 'package:projek_akhir_tpm/views/login_page.dart';
// import 'utils/session_manager.dart';
// import 'views/splash_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toko Aksesoris',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: HomePage(),
    );
  }
}
