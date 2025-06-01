import '../network/api_service.dart';
import '../models/user_model.dart'; // Pastikan ini di-import

class RegisterPresenter {
  final ApiService api;

  RegisterPresenter({required this.api});

  Future<UserModel> register(String name, String email, String password, String role) async {
    return await api.register(name, email, password, role);
  }
}