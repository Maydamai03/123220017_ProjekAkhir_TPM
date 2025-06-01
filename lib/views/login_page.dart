import 'package:flutter/material.dart';
import 'package:projek_akhir_tpm/network/api_service.dart';
import 'package:projek_akhir_tpm/presenters/login_presenter.dart';
import 'package:projek_akhir_tpm/utils/session_manager.dart';
import 'package:projek_akhir_tpm/views/home_page.dart';
import 'package:projek_akhir_tpm/views/register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final LoginPresenter _presenter = LoginPresenter(api: ApiService());
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _handleLogin() async {
    // Basic validation
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan Password tidak boleh kosong!")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _presenter.login(
        _emailController.text,
        _passwordController.text,
      );

      await SessionManager.saveLogin(user);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login berhasil! Selamat datang, ${user.name}")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Login gagal: ${e.toString().replaceFirst('Exception: ', '')}")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
          // Konten Utama Login (dikeluarkan link ke register)
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
                    "ONLINE ACCESSORIES STORE",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 80),

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
                  const SizedBox(height: 24),

                  // Tombol Login
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white))
                      : ElevatedButton(
                          onPressed: _handleLogin,
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
                            "LOGIN",
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
          // --- Link ke Register di bagian bawah layar ---
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom +
                20, // Padding dari bawah layar (termasuk safe area)
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                );
              },
              child: const Text(
                "Don't have an account? Sign up here",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          // --- Akhir Link ke Register ---
        ],
      ),
    );
  }
}
