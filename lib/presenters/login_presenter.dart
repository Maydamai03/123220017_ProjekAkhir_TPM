import '../network/api_service.dart';
import '../models/user_model.dart';

class LoginPresenter {
  final ApiService api;

  LoginPresenter({required this.api});

  Future<UserModel> login(String email, String password) async {
    return await api.login(email, password);
  }
}
