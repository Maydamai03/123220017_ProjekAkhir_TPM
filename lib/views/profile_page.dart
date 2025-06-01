import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projek_akhir_tpm/utils/session_manager.dart';
import 'package:projek_akhir_tpm/views/login_page.dart';
import 'package:projek_akhir_tpm/models/user_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel? _loggedInUser;
  bool _isLoading = true;
  String? _profileImageBase64;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
  try {
    final user = await SessionManager.getLoggedInUser();
    if (user != null) {
      final imageBase64 = await SessionManager.getProfileImageBase64(user.userid!);

      setState(() {
        _loggedInUser = user;
        _profileImageBase64 = imageBase64;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  } catch (e) {
    print("Error loading user data: $e");
    setState(() {
      _isLoading = false;
    });
  }
}

  Future<void> _pickImage(ImageSource source) async {
  final ImagePicker picker = ImagePicker();
  final XFile? pickedFile = await picker.pickImage(source: source);

  if (pickedFile != null && _loggedInUser != null) {
    final bytes = await pickedFile.readAsBytes();
    final base64String = base64Encode(bytes);

    await SessionManager.saveProfileImageBase64(base64String, _loggedInUser!.userid!);

    setState(() {
      _profileImageBase64 = base64String;
    });
  }
}


  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await SessionManager.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _isLoading
          ? const CircularProgressIndicator()
          : _loggedInUser == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Tidak ada data pengguna."),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _handleLogout(context),
                      child: const Text("Kembali ke Login"),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _showImageSourceActionSheet(context),
                          child: CircleAvatar(
                            radius: 80,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: _profileImageBase64 != null
                                ? MemoryImage(base64Decode(_profileImageBase64!))
                                : null,
                            child: _profileImageBase64 == null
                                ? Icon(
                                    Icons.camera_alt,
                                    size: 50,
                                    color: Colors.grey[600],
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Profil Pengguna",
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        Card(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person,
                                        color: Colors.blue),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Nama: ${_loggedInUser!.name}",
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20, thickness: 1),
                                Row(
                                  children: [
                                    const Icon(Icons.email, color: Colors.blue),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Email: ${_loggedInUser!.email}",
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20, thickness: 1),
                                Row(
                                  children: [
                                    const Icon(Icons.shield,
                                        color: Colors.blue),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Role: ${_loggedInUser!.role}",
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () => _handleLogout(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Logout",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
