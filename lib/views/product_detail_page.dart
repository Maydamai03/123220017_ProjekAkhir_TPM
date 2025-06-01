import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:projek_akhir_tpm/models/product_model.dart';
import 'package:projek_akhir_tpm/models/cart_item_model.dart';
import 'package:projek_akhir_tpm/utils/session_manager.dart';
import 'package:intl/intl.dart'; // <<< Import ini

class ProductDetailPage extends StatefulWidget {
  final ProductModel product;
  final VoidCallback onAddToCart;

  const ProductDetailPage(
      {super.key, required this.product, required this.onAddToCart});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;
  late Future<Box<CartItem>> _cartBoxFuture;

  // Deklarasikan formatter di sini
  final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _cartBoxFuture = Hive.openBox<CartItem>('cartBox');
  }

  void _addToCart() async {
    final Box<CartItem> cartBox = await _cartBoxFuture;

    final int? userId = await SessionManager.getLoggedInUserId();

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Anda harus login untuk menambahkan ke keranjang!")),
      );
      return;
    }

    final existingItemIndex = cartBox.values.toList().indexWhere(
          (item) =>
              item.userId == userId && item.product.id == widget.product.id,
        );

    if (existingItemIndex != -1) {
      final existingItem = cartBox.values.toList()[existingItemIndex];
      existingItem.quantity++;
      await existingItem.save();
    } else {
      final newCartItem = CartItem(
        userId: userId,
        product: widget.product,
        quantity: _quantity,
      );
      await cartBox.add(newCartItem);
    }

    widget.onAddToCart();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Produk ditambahkan ke keranjang")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    int totalPrice = widget.product.price * _quantity;

    return Scaffold(
      appBar: AppBar(title: Text(widget.product.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              widget.product.image,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.product.name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  // --- UBAH BARIS INI ---
                  Text(
                      _currencyFormatter
                          .format(widget.product.price), // Format harga
                      style:
                          const TextStyle(fontSize: 18, color: Colors.green)),
                  // --- Akhir Perubahan ---
                  const SizedBox(height: 10),
                  Text(widget.product.description),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (_quantity > 1) {
                                setState(() {
                                  _quantity--;
                                });
                              }
                            },
                            icon: const Icon(Icons.remove),
                          ),
                          Text('$_quantity',
                              style: const TextStyle(fontSize: 18)),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _quantity++;
                              });
                            },
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      // --- UBAH BARIS INI ---
                      Text(
                          "Total: ${_currencyFormatter.format(totalPrice)}", // Format total harga
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      // --- Akhir Perubahan ---
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _addToCart,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text("Add to Cart"),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50)),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
