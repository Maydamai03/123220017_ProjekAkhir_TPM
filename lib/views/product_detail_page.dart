import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:projek_akhir_tpm/models/product_model.dart';
import 'package:projek_akhir_tpm/models/cart_item_model.dart';
import 'package:projek_akhir_tpm/utils/session_manager.dart';
import 'package:intl/intl.dart';

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
      existingItem.quantity += _quantity;
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
      SnackBar(
          content: Text(
              "$_quantity ${widget.product.name} ditambahkan ke keranjang")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    int totalPrice = widget.product.price * _quantity;

    return Scaffold(
      // AppBar dihilangkan sepenuhnya
      body: Stack(
        children: [
          SingleChildScrollView(
            // Padding bawah disesuaikan untuk memberi ruang pada dua elemen di bawah
            padding: const EdgeInsets.only(bottom: 150),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stack baru untuk Gambar Produk dan Tombol Pop
                Stack(
                  children: [
                    // Gambar Produk (mentok atas)
                    Container(
                      height: 440,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: Image.network(
                        widget.product.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image,
                                  size: 60, color: Colors.grey),
                              SizedBox(height: 8),
                              Text("Gagal memuat gambar",
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Tombol Pop (Silang) di pojok kiri atas gambar
                    Positioned(
                      top: 50, // Sesuaikan posisi vertikal
                      left: 18, // Sesuaikan posisi horizontal
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(
                              context); // Kembali ke halaman sebelumnya
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(
                                0.5), // Latar belakang transparan gelap
                            shape: BoxShape.circle, // Bentuk lingkaran
                          ),
                          padding: const EdgeInsets.all(
                              4), // Padding di dalam container
                          child: const Icon(
                            Icons.close, // Ikon silang
                            color: Colors.white, // Warna ikon putih
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama Produk
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Harga Produk Satuan
                      Text(
                        _currencyFormatter.format(widget.product.price),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 69, 69, 69),
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Deskripsi Produk
                      Text(
                        widget.product.description,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bagian untuk Kuantitas dan Total Harga (di atas tombol)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Quantity Selector
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (_quantity > 1) {
                                  setState(() {
                                    _quantity--;
                                  });
                                }
                              },
                              icon: const Icon(Icons.remove,
                                  color: Colors.black87),
                              splashRadius: 20,
                            ),
                            Text(
                              '$_quantity',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _quantity++;
                                });
                              },
                              icon:
                                  const Icon(Icons.add, color: Colors.black87),
                              splashRadius: 20,
                            ),
                          ],
                        ),
                      ),
                      // Total Harga
                      Text(
                        "Total: ${_currencyFormatter.format(totalPrice)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color.fromARGB(255, 75, 75, 75),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Tombol Add to Cart
                  ElevatedButton.icon(
                    onPressed: _addToCart,
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    label: const Text(
                      "Tambahkan ke Keranjang",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8A2BE2),
                      minimumSize: const Size.fromHeight(55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
