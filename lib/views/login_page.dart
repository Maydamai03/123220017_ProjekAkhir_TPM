import 'package:flutter/material.dart';
import '../presenters/login_presenter.dart';
import '../network/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final LoginPresenter _presenter = LoginPresenter(api: ApiService());

  bool _loading = false;

  void _handleLogin() async {
    setState(() => _loading = true);
    try {
      final user = await _presenter.login(_emailCtrl.text, _passwordCtrl.text);
      print("Login berhasil! Token: ${user.token}");
      // TODO: simpan token (misalnya SharedPreferences)
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login gagal: ${e.toString()}")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: _passwordCtrl, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _handleLogin,
              child: _loading ? CircularProgressIndicator() : const Text("Login"),
            )
          ],
        ),
      ),
    );
  }
}
