import 'package:flutter/material.dart';
import 'package:projek_akhir_tpm/views/cart_page.dart';
import 'package:projek_akhir_tpm/views/feedback_page.dart';
import 'package:projek_akhir_tpm/views/product_detail_page.dart';
import 'package:projek_akhir_tpm/views/profile_page.dart';
import '../models/product_model.dart';
import '../network/api_service.dart';
import '../presenters/product_presenter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProductPresenter _presenter = ProductPresenter(api: ApiService());
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  bool _loading = true;
  int _selectedIndex = 0;
  final TextEditingController _searchCtrl = TextEditingController();
  int _newCartItemCount = 0; // hitung produk baru yang belum dilihat

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _newCartItemCount = 0; // Awal dianggap user belum lihat produk baru
    

    _searchCtrl.addListener(() {
      final query = _searchCtrl.text.toLowerCase();
      setState(() {
        _filteredProducts = _products
            .where((p) =>
                p.name.toLowerCase().contains(query) ||
                p.description.toLowerCase().contains(query))
            .toList();
      });
    });
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _presenter.fetchProducts();
      setState(() {
        _products = products;
        _filteredProducts = products;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memuat produk: $e")),
      );
    }
  }

  // Saat user klik bottom navbar:
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;

      if (index == 3) {
        // tab keranjang
        _newCartItemCount = 0; // reset notif karena user sudah lihat keranjang
      }
    });
  }

// Fungsi untuk dipanggil saat ada penambahan produk baru ke keranjang
  void addNewCartItem() {
    setState(() {
      _newCartItemCount++;
    });
  }

  Widget _buildProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              product: product,
              onAddToCart: addNewCartItem, // kirim callback
            ),
          ),
        );

        setState(() {}); // force rebuild biar cart badge update
      },
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: SizedBox(
          width: 200, // supaya bisa scroll horizontal 2 item per row
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image network, sesuaikan url image
              AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  product.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.broken_image, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text("Gagal memuat gambar",
                          style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    // Text(product.description,
                    //     maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text("Rp ${product.price.toString()}",
                        style: const TextStyle(color: Colors.green)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_filteredProducts.isEmpty)
      return const Center(child: Text("Produk tidak ditemukan"));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              labelText: "Cari produk",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 item per baris
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) =>
                _buildProductCard(_filteredProducts[index]),
          ),
        )
      ],
    );
  }

  List<Widget> _pages() => [
        _buildHomeContent(),
        const ProfilePage(),
        const FeedbackPage(),
        const CartPage(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Toko Aksesoris")),
      body: _pages()[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Profil"),
          const BottomNavigationBarItem(
              icon: Icon(Icons.feedback), label: "Saran & Kesan"),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                if (_newCartItemCount > 0)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$_newCartItemCount',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: "Keranjang",
          ),
        ],
      ),
    );
  }
}
