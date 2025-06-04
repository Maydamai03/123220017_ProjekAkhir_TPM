import 'package:flutter/material.dart';
import 'package:projek_akhir_tpm/models/order_model.dart';
import 'package:projek_akhir_tpm/models/user_model.dart';
import 'package:projek_akhir_tpm/network/api_service.dart';
import 'package:projek_akhir_tpm/utils/session_manager.dart';
import 'package:intl/intl.dart';
import 'package:projek_akhir_tpm/presenters/order_presenter.dart';

class HistoryPembayaranPage extends StatefulWidget {
  const HistoryPembayaranPage({super.key});

  @override
  State<HistoryPembayaranPage> createState() => _HistoryPembayaranPageState();
}

class _HistoryPembayaranPageState extends State<HistoryPembayaranPage> {
  List<OrderModel> _userOrders = [];
  int? _currentUserId;
  bool _isLoading = true;
  late OrderPresenter _orderPresenter;

  // Deklarasikan formatter
  final NumberFormat _idrFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final NumberFormat _sgdFormatter = NumberFormat.currency(locale: 'en_SG', symbol: 'SGD ', decimalDigits: 2);
  final NumberFormat _myrFormatter = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ', decimalDigits: 2);
  final NumberFormat _phpFormatter = NumberFormat.currency(locale: 'en_PH', symbol: 'PHP ', decimalDigits: 2);

  String _formatCurrency(double amount, String currencyCode) {
    switch (currencyCode) {
      case 'IDR':
        return _idrFormatter.format(amount);
      case 'SGD':
        return _sgdFormatter.format(amount);
      case 'MYR':
        return _myrFormatter.format(amount);
      case 'PHP':
        return _phpFormatter.format(amount);
      default:
        return '$currencyCode ${amount.toStringAsFixed(2)}'; // Fallback
    }
  }

  @override
  void initState() {
    super.initState();
    _orderPresenter = OrderPresenter(api: ApiService());
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    _currentUserId = await SessionManager.getLoggedInUserId();
    final UserModel? user = await SessionManager.getLoggedInUser();

    if (_currentUserId == null || user == null) {
      setState(() {
        _userOrders = [];
        _isLoading = false;
      });
      return;
    }

    try {
      final List<OrderModel> fetchedOrders = await _orderPresenter.fetchUserOrders(user.token);

      setState(() {
        _userOrders = fetchedOrders
            .where((order) => order.userId == _currentUserId)
            .toList()
            ..sort((a, b) => b.orderDate.compareTo(a.orderDate)); // Pastikan terurut dari terbaru
      });
    } catch (e) {
      print("Gagal mengambil pesanan dari backend: $e");
      _userOrders = [];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memuat riwayat pesanan: ${e.toString().replaceFirst('Exception: ', '')}")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;

    if (_currentUserId == null) {
      bodyContent = const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 50, color: Colors.grey),
              SizedBox(height: 10),
              Text(
                "Silakan login untuk melihat riwayat pesanan Anda.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    } else if (_isLoading) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (_userOrders.isEmpty) {
      bodyContent = const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 50, color: Colors.grey),
              SizedBox(height: 10),
              Text(
                "Anda belum memiliki riwayat pesanan.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              Text(
                "Mulai belanja sekarang untuk melihat riwayat Anda di sini!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    } else {
      bodyContent = ListView.builder(
        itemCount: _userOrders.length,
        itemBuilder: (context, index) {
          final order = _userOrders[index];
          // Hitung nomor urut terbalik
          // Jika ada 6 pesanan, indeks 0 akan jadi #6, indeks 1 jadi #5, dst.
          final int orderNumber = _userOrders.length - index; // <<< UBAH BARIS INI

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ExpansionTile(
              collapsedBackgroundColor: Colors.white,
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              iconColor: const Color.fromARGB(255, 0, 0, 0),
              collapsedIconColor: Colors.grey[700],
              title: Text(
                // Menggunakan orderNumber yang sudah dibalik
                "Pesanan #$orderNumber - ${DateFormat('dd MMM yyyy, HH:mm').format(order.orderDate.toLocal())}", // <<< Ganti format tanggal
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "Total: ${_formatCurrency(order.totalAmount, order.currency)}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color.fromARGB(255, 100, 239, 142)),
                ),
              ),
              children: [
                Divider(height: 1, color: Colors.grey[300]),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow("Penerima", order.recipientName),
                      _buildDetailRow("Alamat", order.deliveryAddress),
                      const SizedBox(height: 10),
                      const Text("Produk Dibeli:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black87)),
                      const SizedBox(height: 5),
                      ...order.products
                          .map((p) => Padding(
                                padding: const EdgeInsets.only(
                                    left: 8.0, bottom: 4.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "${p.name} (x${p.quantity})",
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[800]),
                                      ),
                                    ),
                                    Text(
                                      _formatCurrency(
                                          p.pricePerUnit * p.quantity,
                                          order.currency),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                      const SizedBox(height: 15),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          "Total Akhir: ${_formatCurrency(order.totalAmount, order.currency)}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Color.fromARGB(255, 59, 139, 83)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Belanja"),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
        elevation: 2,
      ),
      body: bodyContent,
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ",
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.black87)),
          Expanded(
              child:
                  Text(value, style: const TextStyle(color: Colors.black54))),
        ],
      ),
    );
  }
}