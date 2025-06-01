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
      case 'IDR': return _idrFormatter.format(amount);
      case 'SGD': return _sgdFormatter.format(amount);
      case 'MYR': return _myrFormatter.format(amount);
      case 'PHP': return _phpFormatter.format(amount);
      default: return '$currencyCode ${amount.toStringAsFixed(2)}'; // Fallback
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
            ..sort((a, b) => b.orderDate.compareTo(a.orderDate));
      } as Function());
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
    if (_currentUserId == null) {
      return const Center(child: Text("Anda harus login untuk melihat riwayat pesanan."));
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userOrders.isEmpty) {
      return const Center(child: Text("Anda belum memiliki riwayat pesanan."));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Riwayat Pembayaran")),
      body: ListView.builder(
        itemCount: _userOrders.length,
        itemBuilder: (context, index) {
          final order = _userOrders[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 4,
            child: ExpansionTile(
              title: Text(
                "Pesanan #${order.id ?? order.userId ?? index + 1} - ${DateFormat('dd MMM yyyy, HH:mm').format(order.orderDate)}", // Perbaikan format tanggal
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text("Total: ${_formatCurrency(order.totalAmount, order.currency)}"),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Penerima: ${order.recipientName}"),
                      const SizedBox(height: 5),
                      Text("Alamat: ${order.deliveryAddress}"),
                      const SizedBox(height: 10),
                      const Text("Produk Dibeli:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      ...order.products.map((p) => Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                        child: Row(
                          children: [
                            Expanded(child: Text("${p.name} (x${p.quantity}) - ${_formatCurrency(p.pricePerUnit * p.quantity, order.currency)}")),
                          ],
                        ),
                      )).toList(),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          "Total Akhir: ${_formatCurrency(order.totalAmount, order.currency)}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}