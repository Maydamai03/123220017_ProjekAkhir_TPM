import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:projek_akhir_tpm/models/cart_item_model.dart';
import 'package:projek_akhir_tpm/models/wishlist_item_model.dart';
import 'package:projek_akhir_tpm/utils/session_manager.dart';
import 'package:projek_akhir_tpm/views/checkout_page.dart';
import 'package:intl/intl.dart';
import 'package:sensors_plus/sensors_plus.dart'; // <<< Import ini
import 'dart:async'; // Untuk StreamSubscription dan Timer
import 'dart:io'; // Untuk Platform.isAndroid/iOS
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

  // --- Variabel untuk deteksi goyangan --- listener untuk akselerometer, mendeteksi goyangan, dan menampilkan dialog.
  StreamSubscription? _accelerometerSubscription;
  double _shakeThreshold = 15.0; // Amplitudo goyangan yang dianggap 'shake'
  int _shakeCount = 0;
  DateTime? _lastShakeTime;
  Duration _shakeInterval = const Duration(
      milliseconds:
          500); // Waktu antara goyangan untuk dianggap "2 kali goyang"
  // --- Akhir Variabel Deteksi Goyangan ---

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDataAndUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onCartViewed?.call();
    });
    _startShakeDetection(); // <<< Mulai deteksi goyangan
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cartBox.listenable().removeListener(_filterItems);
    _wishlistBox.listenable().removeListener(_filterItems);
    _accelerometerSubscription?.cancel(); // <<< Batalkan langganan sensor
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

  // --- Fungsi Deteksi Goyangan ---
  void _startShakeDetection() {
    // Memastikan hanya berjalan di platform yang mendukung sensor (mobile)
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      // Gunakan kIsWeb dari foundation.dart jika ada
      _accelerometerSubscription =
          accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
              .listen((AccelerometerEvent event) {
        // Hitung kekuatan goyangan
        double acceleration = (event.x * event.x +
            event.y * event.y +
            event.z * event.z); // Kuadrat dari magnitudo

        if (acceleration > _shakeThreshold * _shakeThreshold) {
          // Bandingkan dengan kuadrat threshold
          DateTime now = DateTime.now();
          if (_lastShakeTime == null ||
              now.difference(_lastShakeTime!) > _shakeInterval) {
            _shakeCount = 1; // Goyangan pertama dalam interval baru
          } else {
            _shakeCount++; // Goyangan berturut-turut dalam interval
          }
          _lastShakeTime = now;

          if (_shakeCount == 2) {
            // Deteksi 2 kali goyangan
            _shakeCount = 0; // Reset
            _lastShakeTime = null; // Reset waktu
            _showClearCartConfirmationDialog(); // Tampilkan dialog konfirmasi
          }
        }
      });
    } else {
      // Untuk web atau platform lain, bisa tambahkan pesan debug atau abaikan
      print("Sensor akselerometer tidak tersedia di platform ini.");
    }
  }

  Future<void> _showClearCartConfirmationDialog() async {
    if (_userCartItems.isEmpty)
      return; // Jangan tampilkan dialog jika keranjang sudah kosong

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
                Navigator.of(context).pop(false); // Tidak jadi hapus
              },
              child: const Text('Tidak'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Ya, hapus
              },
              child: const Text('Ya, Hapus Semua'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _clearAllCartItems();
    }
  }

  void _clearAllCartItems() async {
    if (_userCartItems.isEmpty) return;

    // Buat salinan untuk iterasi aman, karena item akan dihapus dari _cartBox
    for (var item in List<CartItem>.from(_userCartItems)) {
      await item.delete(); // Hapus setiap item dari Hive
    }
    widget.onCartViewed?.call(); // Perbarui badge notifikasi di HomePage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Semua item di keranjang telah dihapus.")),
    );
  }
  // --- Akhir Fungsi Deteksi Goyangan ---

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
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 50,
            ),
            const SizedBox(width: 8),
            // const Text(
            //   "Belanja Saya",
            //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            // ),
          ],
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
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
                            color: Colors.lightBlue[50],
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
                                color: Colors.blue),
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CheckoutPage(cartItems: _userCartItems),
                              ),
                            ).then((value) {
                              _filterItems();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            textStyle: const TextStyle(fontSize: 18),
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
                      color: Colors.pink[50],
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
                                            color: Colors.blue),
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
