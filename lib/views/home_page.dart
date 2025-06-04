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
import 'package:intl/intl.dart';

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
      if (mounted) {
        // Check if widget is still mounted before showing SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat produk: $e")),
        );
      }
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

  String _shortenName(String name, [int maxLength = 25]) {
    // Increased max length slightly
    if (name.length <= maxLength) return name;
    return '${name.substring(0, maxLength)}...';
  }

  Future<void> _addToCartFromHome(ProductModel product) async {
    if (_currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("Anda harus login untuk menambahkan ke keranjang!")),
        );
      }
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${product.name} ditambahkan ke keranjang")),
      );
    }
  }

  Future<void> _toggleWishlistFromHome(ProductModel product) async {
    if (_currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Anda harus login untuk menambahkan ke wishlist!")),
        );
      }
      return;
    }

    final existingWishlistItemIndex = _wishlistBox.values.toList().indexWhere(
          (item) =>
              item.userId == _currentUserId && item.product.id == product.id,
        );

    if (existingWishlistItemIndex != -1) {
      await _wishlistBox.values.toList()[existingWishlistItemIndex].delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${product.name} dihapus dari wishlist")),
        );
      }
    } else {
      final newWishlistItem = WishlistItem(
        userId: _currentUserId!,
        product: product,
      );
      await _wishlistBox.add(newWishlistItem);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${product.name} ditambahkan ke wishlist")),
        );
      }
    }
    setState(() {}); // Trigger rebuild to update wishlist icon
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
        color: Colors.white, // Warna putih untuk kartu produk
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0)), // Sudut membulat
        elevation: 0, // Sedikit bayangan
        margin: const EdgeInsets.all(0.4), // Jarak antar kartu
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(0)), // Bulatkan sudut atas
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  product.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image,
                          size: 40,
                          color: Colors.grey[400]), // Ikon lebih terang
                      const SizedBox(height: 8),
                      Text(
                        "Image failed to load", // Pesan error bahasa inggris
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 2), // Padding lebih proporsional
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _shortenName(product.name),
                          style: TextStyle(
                            fontWeight: FontWeight.w700, // Lebih tebal
                            fontSize: 14, // Sedikit lebih besar
                            color: Colors.grey[800], // Warna teks produk
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isInWishlist ? Icons.favorite : Icons.favorite_border,
                          color: isInWishlist
                              ? Colors.red
                              : Colors.grey[
                                  400], // Warna merah jika di wishlist, abu-abu jika tidak
                          size: 20,
                        ),
                        onPressed: () => _toggleWishlistFromHome(product),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: isInWishlist
                            ? 'Remove from Wishlist'
                            : 'Add to Wishlist',
                      ),
                    ],
                  ),
                  const SizedBox(height: 1), // Jarak lebih
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _currencyFormatter.format(product.price),
                        style: TextStyle(
                          color: Colors.grey[900], // Warna harga lebih gelap
                          fontWeight: FontWeight.w600, // Lebih tebal
                          fontSize: 14, // Sedikit lebih besar
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_shopping_cart,
                            color: Colors.grey[700], // Warna ikon keranjang
                            size: 20),
                        onPressed: () => _addToCartFromHome(product),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Add to Cart',
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
    return Column(
      children: [
        // Custom AppBar
        Container(
          padding: const EdgeInsets.fromLTRB(
              16.0, 40.0, 16.0, 16.0), // Padding disesuaikan untuk status bar
          color: const Color.fromARGB(255, 255, 255, 255), // Warna AppBar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // const Text(
              //   "Our Products",
              //   style: TextStyle(
              //     color: Colors.white,
              //     fontSize: 28,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
              const SizedBox(height: 15),
              TextField(
                controller: _searchCtrl,
                style: const TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0)), // Warna teks input putih
                decoration: InputDecoration(
                  hintText: "Search for products...",
                  hintStyle: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
                  prefixIcon: const Icon(Icons.search, color: Color.fromARGB(179, 0, 0, 0)),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 234, 234, 234), // Background search bar yang lebih gelap
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12.0), // Sudut lebih membulat
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(
                        color: Colors.grey, width: 2.0), // Border saat fokus
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 14.0, horizontal: 16.0),
                ),
              ),
            ],
          ),
        ),

        _loading
            ? const Expanded(
                child: Center(
                    child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.grey))))
            : _filteredProducts.isEmpty
                ? const Expanded(
                    child: Center(
                        child: Text("No products found",
                            style: TextStyle(color: Colors.grey))))
                : Expanded(
                    child: GridView.builder(
                      padding:
                          const EdgeInsets.all(3), // Padding keseluruhan grid
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 0, // Jarak horizontal
                        mainAxisSpacing: 0, // Jarak vertikal
                        childAspectRatio: 0.6, // Sesuaikan rasio ini jika perlu agar konten tidak terpotong
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
        _buildHomeContent(), // Home page dengan search bar dan grid produk
        CartPage(onCartViewed: _resetCartNotification),
        const HistoryPembayaranPage(),
        const ProfilePage(),
        const FeedbackPage(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Background keseluruhan Scaffold
      body: _pages()[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor:
            Colors.grey[600], // Warna ikon tidak terpilih lebih ke abu-abu
        backgroundColor: Colors.white, // Background bottom nav bar putih
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
            label: "Cart", // Ubah ke English
          ),
          const BottomNavigationBarItem(
              icon: Icon(Icons.history), label: "History"), // Ubah ke English
          const BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Profile"), // Ubah ke English
          const BottomNavigationBarItem(
              icon: Icon(Icons.feedback), label: "Feedback"), // Ubah ke English
        ],
      ),
    );
  }
}
