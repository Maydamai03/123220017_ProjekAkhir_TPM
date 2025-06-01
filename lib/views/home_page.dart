import 'package:flutter/material.dart';
import 'package:projek_akhir_tpm/views/cart_page.dart';
import 'package:projek_akhir_tpm/views/feedback_page.dart';
import 'package:projek_akhir_tpm/views/product_detail_page.dart';
import 'package:projek_akhir_tpm/views/profile_page.dart';
import 'package:projek_akhir_tpm/views/history_pembayaran_page.dart';
import 'package:projek_akhir_tpm/models/product_model.dart';
import 'package:projek_akhir_tpm/network/api_service.dart';
import 'package:projek_akhir_tpm/presenters/product_presenter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:projek_akhir_tpm/models/cart_item_model.dart';
import 'package:projek_akhir_tpm/models/wishlist_item_model.dart';
import 'package:projek_akhir_tpm/utils/session_manager.dart';
import 'package:intl/intl.dart'; // <<< Import ini

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
  int _newCartItemCount = 0;

  late Box<CartItem> _cartBox;
  late Box<WishlistItem> _wishlistBox;
  int? _currentUserId;

  // Deklarasikan formatter di sini sebagai final
  final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
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

  Future<void> _loadInitialData() async {
    _cartBox = await Hive.openBox<CartItem>('cartBox');
    _wishlistBox = await Hive.openBox<WishlistItem>('wishlistBox');
    _currentUserId = await SessionManager.getLoggedInUserId();
    _loadProducts();
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

  void _resetCartNotification() {
    setState(() {
      _newCartItemCount = 0;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 1) {
        // Keranjang
        _resetCartNotification();
      }
    });
  }

  void addNewCartItem() {
    setState(() {
      _newCartItemCount++;
    });
  }

  String _shortenName(String name, [int maxLength = 20]) {
    if (name.length <= maxLength) return name;
    return '${name.substring(0, maxLength)}...';
  }

  Future<void> _addToCartFromHome(ProductModel product) async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Anda harus login untuk menambahkan ke keranjang!")),
      );
      return;
    }

    final existingItemIndex = _cartBox.values.toList().indexWhere(
          (item) =>
              item.userId == _currentUserId && item.product.id == product.id,
        );

    if (existingItemIndex != -1) {
      final existingItem = _cartBox.values.toList()[existingItemIndex];
      existingItem.quantity++;
      await existingItem.save();
    } else {
      final newCartItem = CartItem(
        userId: _currentUserId!,
        product: product,
        quantity: 1,
      );
      await _cartBox.add(newCartItem);
    }
    addNewCartItem();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${product.name} ditambahkan ke keranjang")),
    );
  }

  Future<void> _toggleWishlistFromHome(ProductModel product) async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Anda harus login untuk menambahkan ke wishlist!")),
      );
      return;
    }

    final existingWishlistItemIndex = _wishlistBox.values.toList().indexWhere(
          (item) =>
              item.userId == _currentUserId && item.product.id == product.id,
        );

    if (existingWishlistItemIndex != -1) {
      await _wishlistBox.values.toList()[existingWishlistItemIndex].delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${product.name} dihapus dari wishlist")),
      );
    } else {
      final newWishlistItem = WishlistItem(
        userId: _currentUserId!,
        product: product,
      );
      await _wishlistBox.add(newWishlistItem);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${product.name} ditambahkan ke wishlist")),
      );
    }
    setState(() {});
  }

  Widget _buildProductCard(ProductModel product) {
    bool isInWishlist = _wishlistBox.values.any(
      (item) => item.userId == _currentUserId && item.product.id == product.id,
    );

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              product: product,
              onAddToCart: addNewCartItem,
            ),
          ),
        );
      },
      child: Card(
        color: const Color.fromARGB(255, 245, 245, 245),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        margin: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar produk (tanpa tombol di atasnya)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
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
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment
                        .spaceBetween, // Untuk menempatkan tombol di kanan
                    children: [
                      Expanded(
                        // Agar nama produk tidak overflow
                        child: Text(
                          _shortenName(product.name),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow
                              .ellipsis, // Jika nama terlalu panjang
                          maxLines: 1,
                        ),
                      ),
                      // Tombol Wishlist di samping nama produk
                      IconButton(
                        icon: Icon(
                          isInWishlist ? Icons.favorite : Icons.favorite_border,
                          color: isInWishlist ? Colors.red : Colors.grey,
                        ),
                        onPressed: () => _toggleWishlistFromHome(product),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        tooltip: 'Tambah ke Wishlist',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _currencyFormatter
                            .format(product.price), // Format harga di sini
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      // Tombol Add Keranjang di samping harga
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart,
                            color: Color.fromARGB(255, 49, 49, 49), size: 20),
                        onPressed: () => _addToCartFromHome(product),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        tooltip: 'Tambah ke Keranjang',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
              crossAxisCount: 2,
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
        CartPage(onCartViewed: _resetCartNotification),
        const HistoryPembayaranPage(),
        const ProfilePage(),
        const FeedbackPage(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages()[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
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
          const BottomNavigationBarItem(
              icon: Icon(Icons.history), label: "Riwayat"),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Profil"),
          const BottomNavigationBarItem(
              icon: Icon(Icons.feedback), label: "Saran & Kesan"),
        ],
      ),
    );
  }
}
