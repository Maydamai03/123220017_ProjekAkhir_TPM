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
import 'package:intl/intl.dart';

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

  // Sesuaikan nilai kurs manual Anda jika diperlukan
  final Map<String, double> _exchangeRates = {
    'IDR': 1.0,
    'SGD': 0.000085,
    'MYR': 0.00031,
    'PHP': 0.0036,
  };

  final NumberFormat _idrFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin lokasi ditolak.')),
            );
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Izin lokasi ditolak permanen. Silakan ubah di pengaturan aplikasi.')),
          );
        }
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
            "${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.postalCode ?? ''}, ${place.country ?? ''}";
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Tidak dapat menemukan alamat dari lokasi saat ini.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mendapatkan lokasi: $e")),
        );
      }
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
        await item.delete(); // Menghapus item dari Hive box
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pesanan berhasil dibuat!")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const HistoryPembayaranPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Gagal membuat pesanan: ${e.toString().replaceFirst('Exception: ', '')}")),
        );
      }
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
      backgroundColor: Colors.grey[100], // Background yang terang
      appBar: AppBar(
        title: const Text(
          "Checkout",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.grey[900], // AppBar gelap
        iconTheme:
            const IconThemeData(color: Colors.white), // Tombol kembali putih
        elevation: 0, // Hapus bayangan AppBar
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[700]!),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Detail Penerima ---
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Detail Pengiriman",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800]),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _recipientNameController,
                            style: TextStyle(color: Colors.grey[900]),
                            decoration: InputDecoration(
                              labelText: "Nama Penerima",
                              labelStyle: TextStyle(color: Colors.grey[600]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey[400]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: Colors.grey[700]!, width: 2),
                              ),
                              prefixIcon: Icon(Icons.person_outline,
                                  color: Colors.grey[500]),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _addressController,
                                  style: TextStyle(color: Colors.grey[900]),
                                  decoration: InputDecoration(
                                    labelText: "Alamat untuk Pengiriman",
                                    labelStyle:
                                        TextStyle(color: Colors.grey[600]),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          BorderSide(color: Colors.grey[400]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: Colors.grey[700]!, width: 2),
                                    ),
                                    prefixIcon: Icon(Icons.location_on_outlined,
                                        color: Colors.grey[500]),
                                  ),
                                  maxLines: 3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height:
                                    56, // Menyesuaikan tinggi dengan TextField
                                child: ElevatedButton(
                                  onPressed: _getCurrentLocationAndFillAddress,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.grey[200], // Tombol abu-abu muda
                                    foregroundColor:
                                        Colors.grey[700], // Ikon abu-abu
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 2,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                  ),
                                  child:
                                      const Icon(Icons.my_location, size: 24),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // --- Ringkasan Pesanan ---
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Ringkasan Pesanana",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800]),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Harga Keranjang:",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[700]),
                              ),
                              Text(
                                _idrFormatter.format(totalIDR),
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[900]),
                              ),
                            ],
                          ),
                          const Divider(
                              height: 30, thickness: 1, color: Colors.grey),
                          DropdownButtonFormField<String>(
                            value: _selectedCurrency,
                            decoration: InputDecoration(
                              labelText: "Konversi Mata Uang",
                              labelStyle: TextStyle(color: Colors.grey[600]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey[400]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: Colors.grey[700]!, width: 2),
                              ),
                            ),
                            dropdownColor: Colors.white,
                            style: TextStyle(color: Colors.grey[900]),
                            items: _exchangeRates.keys.map((String value) {
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
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Pembayaran:",
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[900]),
                              ),
                              Text(
                                _selectedCurrency == 'IDR'
                                    ? _idrFormatter
                                        .format(_convertedTotalAmount)
                                    : '${_selectedCurrency} ${_genericCurrencyFormatter.format(_convertedTotalAmount)}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 59, 139, 83),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- Tombol Buat Pesanan ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _placeOrder,
                      icon: const Icon(Icons.shopping_cart_checkout,
                          color: Colors.white),
                      label: const Text(
                        "Buat Pesanan",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8A2BE2), // Warna ungu
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 7, // Tambahkan sedikit bayangan
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
