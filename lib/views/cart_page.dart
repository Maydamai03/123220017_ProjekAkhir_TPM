import 'package:flutter/material.dart';

class CartPage extends StatelessWidget {
  static final List<Map<String, dynamic>> cartItems = [];

  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Keranjang")),
      body: ListView.builder(
        itemCount: cartItems.length,
        itemBuilder: (context, index) {
          final product = cartItems[index]['product'];
          final quantity = cartItems[index]['quantity'];
          return ListTile(
            leading: Image.network(product.image,
                width: 50, height: 50, fit: BoxFit.cover),
            title: Text(product.name),
            subtitle: Text("Jumlah: $quantity"),
            trailing:
                Text("Rp ${(product.price * quantity).toStringAsFixed(0)}"),
          );
        },
      ),
    );
  }
}
