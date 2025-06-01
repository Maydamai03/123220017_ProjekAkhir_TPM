import 'package:hive/hive.dart';
import 'package:projek_akhir_tpm/models/product_model.dart';

part 'cart_item_model.g.dart'; // Ini akan dibuat otomatis oleh hive_generator

@HiveType(typeId: 1) // typeId UNIK, contoh: 1
class CartItem extends HiveObject {
  @HiveField(0)
  int userId; // ID pengguna yang memiliki keranjang ini

  @HiveField(1)
  ProductModel product;

  @HiveField(2)
  int quantity;

  CartItem(
      {required this.userId, required this.product, required this.quantity});
}
