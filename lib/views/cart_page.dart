import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:projek_akhir_tpm/models/cart_item_model.dart';
import 'package:projek_akhir_tpm/models/wishlist_item_model.dart';
import 'package:projek_akhir_tpm/utils/session_manager.dart';
import 'package:projek_akhir_tpm/views/checkout_page.dart';
import 'package:intl/intl.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class CartPage extends StatefulWidget {
  final VoidCallback? onCartViewed;

  const CartPage({super.key, this.onCartViewed});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Box<CartItem> _cartBox;
  late Box<WishlistItem> _wishlistBox;

  List<CartItem> _userCartItems = [];
  List<WishlistItem> _userWishlistItems = [];

  int? _currentUserId;

  final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // --- Variabel untuk deteksi goyangan ---
  StreamSubscription? _accelerometerSubscription;
  double _shakeThreshold = 25.0; // Peningkatan dari 15.0 menjadi 25.0 (contoh)
  int _shakeCount = 0;
  DateTime? _lastShakeTime;
  Duration _shakeInterval = const Duration(milliseconds: 1000); // Peningkatan dari 500ms menjadi 1000ms (contoh)

  // --- Variabel baru untuk mencegah spam pop-up ---
  bool _isDialogShowing = false;
  // --- Akhir Variabel Deteksi Goyangan ---

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDataAndUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onCartViewed?.call();
    });
    _startShakeDetection(); // Mulai deteksi goyangan saat CartPage dibuat
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cartBox.listenable().removeListener(_filterItems);
    _wishlistBox.listenable().removeListener(_filterItems);
    _accelerometerSubscription?.cancel(); // Pastikan langganan sensor dibatalkan
    super.dispose();
  }

  Future<void> _loadDataAndUser() async {
    if (!Hive.isBoxOpen('cartBox')) {
      _cartBox = await Hive.openBox<CartItem>('cartBox');
    } else {
      _cartBox = Hive.box<CartItem>('cartBox');
    }

    if (!Hive.isBoxOpen('wishlistBox')) {
      _wishlistBox = await Hive.openBox<WishlistItem>('wishlistBox');
    } else {
      _wishlistBox = Hive.box<WishlistItem>('wishlistBox');
    }

    _currentUserId = await SessionManager.getLoggedInUserId();
    _filterItems();
    _cartBox.listenable().addListener(_filterItems);
    _wishlistBox.listenable().addListener(_filterItems);
  }

  void _filterItems() {
    if (_currentUserId == null) {
      setState(() {
        _userCartItems = [];
        _userWishlistItems = [];
      });
      return;
    }
    setState(() {
      _userCartItems = _cartBox.values
          .where((item) => item.userId == _currentUserId)
          .toList();
      _userWishlistItems = _wishlistBox.values
          .where((item) => item.userId == _currentUserId)
          .toList();
    });
  }

  // --- Fungsi untuk mengaktifkan/menonaktifkan deteksi goyangan ---
  void _setShakeDetectionEnabled(bool enable) {
    if (enable) {
      // Hanya mulai jika belum aktif atau sedang di-pause
      if (_accelerometerSubscription == null || _accelerometerSubscription!.isPaused) {
        _startShakeDetection();
      }
    } else {
      // Pause stream jika aktif
      _accelerometerSubscription?.pause();
    }
  }
  // --- Akhir fungsi kontrol deteksi goyangan ---

  // --- Fungsi Deteksi Goyangan (MODIFIKASI DI SINI) ---
  void _startShakeDetection() {
    // Pastikan subscription sebelumnya dibatalkan jika ada
    _accelerometerSubscription?.cancel();

    // Memastikan hanya berjalan di platform yang mendukung sensor (mobile)
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _accelerometerSubscription =
          accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
              .listen((AccelerometerEvent event) {
        // --- Cek apakah dialog sedang tampil ---
        if (_isDialogShowing) {
          return; // Abaikan event goyangan jika dialog sudah tampil
        }

        // Hitung kekuatan goyangan
        double acceleration = (event.x * event.x + event.y * event.y + event.z * event.z);

        if (acceleration > _shakeThreshold * _shakeThreshold) {
          DateTime now = DateTime.now();
          if (_lastShakeTime == null || now.difference(_lastShakeTime!) > _shakeInterval) {
            _shakeCount = 1;
          } else {
            _shakeCount++;
          }
          _lastShakeTime = now;

          if (_shakeCount == 2) {
            _shakeCount = 0;
            _lastShakeTime = null;
            _showClearCartConfirmationDialog();
          }
        }
      });
    } else {
      print("Sensor akselerometer tidak tersedia di platform ini.");
    }
  }
  // --- Akhir Fungsi Deteksi Goyangan ---

  // --- Fungsi showClearCartConfirmationDialog (MODIFIKASI DI SINI) ---
  Future<void> _showClearCartConfirmationDialog() async {
    if (_userCartItems.isEmpty) return;

    // Set flag bahwa dialog sedang tampil
    _isDialogShowing = true;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Keranjang?'),
          content: const Text(
              'Apakah Anda yakin ingin menghapus semua item di keranjang?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Tidak'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Ya, Hapus Semua'),
            ),
          ],
        );
      },
    );

    // Reset flag setelah dialog ditutup
    _isDialogShowing = false;

    if (confirm == true) {
      _clearAllCartItems();
    }
  }
  // --- Akhir Fungsi showClearCartConfirmationDialog ---

  void _clearAllCartItems() async {
    if (_userCartItems.isEmpty) return;

    for (var item in List<CartItem>.from(_userCartItems)) {
      await item.delete();
    }
    widget.onCartViewed?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Semua item di keranjang telah dihapus.")),
    );
  }

  void _incrementQuantity(CartItem item) async {
    item.quantity++;
    await item.save();
  }

  void _decrementQuantity(CartItem item) async {
    if (item.quantity > 1) {
      item.quantity--;
      await item.save();
    } else {
      await item.delete();
    }
  }

  void _removeItemFromCart(CartItem item) async {
    await item.delete();
  }

  void _removeItemFromWishlist(WishlistItem item) async {
    await item.delete();
  }

  void _addToCartFromWishlist(WishlistItem wishlistItem) async {
    if (_currentUserId == null) return;

    final existingCartItemIndex = _cartBox.values.toList().indexWhere(
          (item) =>
              item.userId == _currentUserId &&
              item.product.id == wishlistItem.product.id,
        );

    if (existingCartItemIndex != -1) {
      final existingCartItem = _cartBox.values.toList()[existingCartItemIndex];
      existingCartItem.quantity++;
      await existingCartItem.save();
    } else {
      final newCartItem = CartItem(
        userId: _currentUserId!,
        product: wishlistItem.product,
        quantity: 1,
      );
      await _cartBox.add(newCartItem);
    }
    await wishlistItem.delete();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              "${wishlistItem.product.name} ditambahkan ke keranjang dan dihapus dari wishlist")),
    );
    widget.onCartViewed?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Center(
          child:
              Text("Anda harus login untuk melihat keranjang dan wishlist."));
    }

    double totalCartAmount = _userCartItems.fold(
        0.0, (sum, item) => sum + (item.product.price * item.quantity));

    return Scaffold(
     backgroundColor: const Color.fromARGB(255, 255, 255, 255), // Ini adalah baris kuncinya

      appBar: AppBar(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255), // Ini adalah baris kuncinya

        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 50,
            ),
            const SizedBox(width: 8),
          ],
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color.fromARGB(255, 24, 24, 24),
          unselectedLabelColor: Colors.grey,
          indicatorColor: Color.fromARGB(255, 24, 24, 24),
          tabs: const [
            Tab(text: "Keranjang", icon: Icon(Icons.shopping_cart)),
            Tab(text: "Wishlist", icon: Icon(Icons.favorite)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab Keranjang
          _userCartItems.isEmpty
              ? const Center(child: Text("Keranjang Anda kosong."))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _userCartItems.length,
                        itemBuilder: (context, index) {
                          final item = _userCartItems[index];
                          return Card(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Image.network(
                                    item.product.image,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.broken_image,
                                                size: 50, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        Text(
                                            _currencyFormatter
                                                .format(item.product.price),
                                            style: const TextStyle(
                                                color: Colors.green)),
                                        Row(
                                          children: [
                                            IconButton(
                                              onPressed: () =>
                                                  _decrementQuantity(item),
                                              icon: const Icon(
                                                  Icons.remove_circle_outline),
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                            Text('${item.quantity}'),
                                            IconButton(
                                              onPressed: () =>
                                                  _incrementQuantity(item),
                                              icon: const Icon(
                                                  Icons.add_circle_outline),
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              onPressed: () =>
                                                  _removeItemFromCart(item),
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              tooltip: 'Hapus Item',
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
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total Pembayaran:",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _currencyFormatter.format(totalCartAmount),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 59, 139, 83)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: () {
                            if (_userCartItems.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Keranjang kosong, tidak bisa checkout!")),
                              );
                              return;
                            }
                            // --- Penting: NONAKTIFKAN deteksi goyangan sebelum navigasi ---
                            _setShakeDetectionEnabled(false);

                            Navigator.push( // Tetap gunakan push agar bisa kembali
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CheckoutPage(cartItems: _userCartItems),
                              ),
                            ).then((value) {
                              // --- Penting: AKTIFKAN kembali deteksi goyangan saat kembali ---
                              _setShakeDetectionEnabled(true);
                              _filterItems(); // Perbarui item jika ada perubahan di checkout
                              widget.onCartViewed?.call(); // Perbarui badge di Home
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF8A2BE2),
                            foregroundColor: Color.fromARGB(255, 255, 255, 255),
                            minimumSize: const Size.fromHeight(55),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                          child: const Text("Checkout"),
                        ),
                      ),
                    ),
                  ],
                ),
          // Tab Wishlist
          _userWishlistItems.isEmpty
              ? const Center(child: Text("Wishlist Anda kosong."))
              : ListView.builder(
                  itemCount: _userWishlistItems.length,
                  itemBuilder: (context, index) {
                    final item = _userWishlistItems[index];
                    return Card(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Image.network(
                              item.product.image,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image,
                                      size: 50, color: Colors.grey),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  Text(
                                      _currencyFormatter
                                          .format(item.product.price),
                                      style:
                                          const TextStyle(color: Colors.green)),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        onPressed: () =>
                                            _addToCartFromWishlist(item),
                                        icon: const Icon(
                                            Icons.add_shopping_cart,
                                            color: Color.fromARGB(
                                                255, 54, 54, 54)),
                                        tooltip: 'Tambah ke Keranjang',
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            _removeItemFromWishlist(item),
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        tooltip: 'Hapus dari Wishlist',
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
                  },
                ),
        ],
      ),
    );
  }
}