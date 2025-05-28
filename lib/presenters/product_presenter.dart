import '../models/product_model.dart';
import '../network/api_service.dart';

class ProductPresenter {
  final ApiService api;

  ProductPresenter({required this.api});

  Future<List<ProductModel>> fetchProducts() async {
    return await api.getProducts();
  }
}
