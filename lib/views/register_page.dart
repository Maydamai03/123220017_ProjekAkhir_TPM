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

  final RegisterPresenter _registerPresenter =
      RegisterPresenter(api: ApiService());
  final ApiService _apiService = ApiService();

  // Regular expression untuk validasi email
  // Ini adalah regex dasar untuk memeriksa keberadaan '@' dan format umum.
  // Untuk validasi email yang lebih ketat, regex bisa jauh lebih kompleks.
  final RegExp _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

  Future<void> _handleRegister() async {
    // Validasi input di frontend
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
      // <<< Validasi Email di sini
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
      appBar: AppBar(title: const Text("Registrasi Akun")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType
                    .emailAddress, // Penting: Menampilkan keyboard email
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "Kata Sandi",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: "Konfirmasi Kata Sandi",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _handleRegister,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: const Text("Daftar"),
                    ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Kembali ke halaman login
                },
                child: const Text("Sudah punya akun? Login di sini"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
