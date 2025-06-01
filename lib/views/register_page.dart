import 'package:flutter/material.dart';
import 'package:projek_akhir_tpm/network/api_service.dart';
import 'package:projek_akhir_tpm/presenters/register_presenter.dart';
import 'package:projek_akhir_tpm/utils/session_manager.dart';
import 'package:projek_akhir_tpm/views/home_page.dart';
import 'package:projek_akhir_tpm/models/user_model.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final RegisterPresenter _registerPresenter =
      RegisterPresenter(api: ApiService());
  final ApiService _apiService = ApiService();

  final RegExp _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

  Future<void> _handleRegister() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Semua kolom harus diisi!")),
      );
      return;
    }

    if (!_emailRegex.hasMatch(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Format email tidak valid. Harus mengandung '@' dan domain.")),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Kata sandi dan konfirmasi kata sandi tidak cocok!")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _registerPresenter.register(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
        'user',
      );

      final UserModel loggedInUser = await _apiService.login(
        _emailController.text,
        _passwordController.text,
      );

      await SessionManager.saveLogin(loggedInUser);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Registrasi berhasil! Selamat datang, ${loggedInUser.name}")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Registrasi atau Login gagal: ${e.toString().replaceFirst('Exception: ', '')}")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gambar Background Fullscreen
          Positioned.fill(
            child: Image.asset(
              'assets/images/loginbg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Overlay Hitam Transparan
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          // Konten Utama Register (dikeluarkan link ke login)
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Text "MAYSSORIES"
                  const Text(
                    "MAYSSORIES",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "CREATE NEW ACCOUNT",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 50),

                  // Input Username/Name
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Username",
                      hintStyle: TextStyle(color: Colors.white54),
                      fillColor: Colors.white.withOpacity(0.4),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 20.0),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input Email
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Email",
                      hintStyle: TextStyle(color: Colors.white54),
                      fillColor: Colors.white.withOpacity(0.4),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 20.0),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input Password (dengan toggle visibility)
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Password",
                      hintStyle: TextStyle(color: Colors.white54),
                      fillColor: Colors.white.withOpacity(0.4),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white54,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 20.0),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input Confirm Password (dengan toggle visibility)
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Confirm Password",
                      hintStyle: TextStyle(color: Colors.white54),
                      fillColor: Colors.white.withOpacity(0.4),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white54,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 20.0),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Daftar
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white))
                      : ElevatedButton(
                          onPressed: _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 15.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "SIGN UP",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                  // Hapus SizedBox dan TextButton dari sini
                  // const SizedBox(height: 20),
                  // TextButton(...)
                ],
              ),
            ),
          ),
          // --- Link Kembali ke Login di bagian bawah layar ---
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom +
                20, // Padding dari bawah layar (termasuk safe area)
            child: TextButton(
              onPressed: () {
                Navigator.pop(context); // Kembali ke halaman login
              },
              child: const Text(
                "Already have an account? Login here",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          // --- Akhir Link Kembali ke Login ---
        ],
      ),
    );
  }
}
