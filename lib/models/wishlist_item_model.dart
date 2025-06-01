import 'package:hive/hive.dart';
import 'package:projek_akhir_tpm/models/product_model.dart';

part 'wishlist_item_model.g.dart';

@HiveType(typeId: 2) // typeId UNIK, contoh: 2 (ProductModel=0, CartItem=1)
class WishlistItem extends HiveObject {
  @HiveField(0)
  int userId; // ID pengguna yang memiliki wishlist ini

  @HiveField(1)
  ProductModel product; // Produk yang ada di wishlist

  WishlistItem({required this.userId, required this.product});
}