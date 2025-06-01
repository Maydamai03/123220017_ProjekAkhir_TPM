import '../network/api_service.dart';
import '../models/order_model.dart';

class OrderPresenter {
  final ApiService api;

  OrderPresenter({required this.api});

  /// Mengirim pesanan baru ke backend.
  /// Mengembalikan OrderModel yang dibuat dari respons backend.
  Future<OrderModel> placeOrder(String token, OrderModel order) async {
    return await api.createOrder(token, order);
  }

  /// Mengambil daftar pesanan dari backend untuk user yang login.
  Future<List<OrderModel>> fetchUserOrders(String token) async {
    return await api.getOrders(token);
  }
}
