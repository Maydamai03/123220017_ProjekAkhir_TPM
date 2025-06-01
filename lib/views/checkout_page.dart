import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:projek_akhir_tpm/models/cart_item_model.dart';
import 'package:projek_akhir_tpm/models/order_model.dart';
import 'package:projek_akhir_tpm/models/user_model.dart';
import 'package:projek_akhir_tpm/network/api_service.dart';
import 'package:projek_akhir_tpm/utils/session_manager.dart';
import 'package:projek_akhir_tpm/views/history_pembayaran_page.dart';
import 'package:projek_akhir_tpm/presenters/order_presenter.dart';
import 'package:intl/intl.dart'; // <<< Import ini

class CheckoutPage extends StatefulWidget {
  final List<CartItem> cartItems;

  const CheckoutPage({super.key, required this.cartItems});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _recipientNameController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String _selectedCurrency = 'IDR';
  double _convertedTotalAmount = 0.0;
  bool _isLoading = false;
  late OrderPresenter _orderPresenter;

  final Map<String, double> _exchangeRates = {
    'IDR': 1.0,
    'SGD': 0.000085, // Sesuaikan nilai kurs manual Anda
    'MYR': 0.00031,
    'PHP': 0.0036,
  };

  // Deklarasikan formatter untuk IDR
  final NumberFormat _idrFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  // Deklarasikan formatter generik untuk mata uang lain (dengan 2 desimal)
  final NumberFormat _genericCurrencyFormatter =
      NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _orderPresenter = OrderPresenter(api: ApiService());
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _calculateAndConvertTotal();
    final user = await SessionManager.getLoggedInUser();
    if (user != null) {
      _recipientNameController.text = user.name;
    }
  }

  void _calculateAndConvertTotal() {
    setState(() {
      _isLoading = true;
    });

    double totalIDR = widget.cartItems
        .fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
    double rate = _exchangeRates[_selectedCurrency] ?? 1.0;

    setState(() {
      _convertedTotalAmount = totalIDR * rate;
      _isLoading = false;
    });
  }

  Future<void> _getCurrentLocationAndFillAddress() async {
    setState(() {
      _isLoading = true;
    });
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin lokasi ditolak.')),
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Izin lokasi ditolak permanen. Silakan ubah di pengaturan aplikasi.')),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        _addressController.text =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Tidak dapat menemukan alamat dari lokasi saat ini.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mendapatkan lokasi: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _placeOrder() async {
    if (_recipientNameController.text.isEmpty ||
        _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Nama penerima dan alamat tidak boleh kosong!")),
      );
      return;
    }

    final UserModel? user = await SessionManager.getLoggedInUser();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Anda harus login untuk membuat pesanan!")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final List<OrderedProduct> orderedProducts = widget.cartItems
          .map((item) => OrderedProduct.fromCartItem(item))
          .toList();

      final newOrder = OrderModel(
        userId: user.userid,
        recipientName: _recipientNameController.text,
        deliveryAddress: _addressController.text,
        currency: _selectedCurrency,
        totalAmount: _convertedTotalAmount,
        orderDate: DateTime.now(),
        products: orderedProducts,
      );

      final OrderModel createdOrder =
          await _orderPresenter.placeOrder(user.token, newOrder);
      print(
          "Order created on backend with ID (backend does not return specific ID): ${createdOrder.userId}");

      final cartBox = await Hive.openBox<CartItem>('cartBox');
      for (var item in widget.cartItems) {
        await item.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pesanan berhasil dibuat!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HistoryPembayaranPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Gagal membuat pesanan: ${e.toString().replaceFirst('Exception: ', '')}")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _recipientNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double totalIDR = widget.cartItems
        .fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));

    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Detail Penerima:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _recipientNameController,
                    decoration: const InputDecoration(
                      labelText: "Nama Penerima",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: "Alamat Pengiriman",
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.location_on),
                        onPressed: _getCurrentLocationAndFillAddress,
                        tooltip: "Gunakan Lokasi Saat Ini",
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Total Belanja:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  // --- UBAH BARIS INI ---
                  Text(
                    _idrFormatter.format(totalIDR) + " (Total Keranjang Awal)",
                    style: const TextStyle(fontSize: 16),
                  ),
                  // --- Akhir Perubahan ---
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: "Konversi ke Mata Uang",
                      border: OutlineInputBorder(),
                    ),
                    items: <String>['IDR', 'SGD', 'MYR', 'PHP']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCurrency = newValue;
                        });
                        _calculateAndConvertTotal();
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  // --- UBAH BARIS INI ---
                  Text(
                    "Total Pembayaran: ${_selectedCurrency == 'IDR' ? _idrFormatter.format(_convertedTotalAmount) : _selectedCurrency + ' ' + _genericCurrencyFormatter.format(_convertedTotalAmount)}",
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                  // --- Akhir Perubahan ---
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _placeOrder,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text("Buat Pesanan"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
