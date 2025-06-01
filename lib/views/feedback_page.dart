import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal dan waktu

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  String _selectedTimezone = 'WITA'; // Default zona waktu konversi

  // Waktu operasional toko di WIB (UTC+7)
  final TimeOfDay _openingTimeWIB = TimeOfDay(hour: 9, minute: 0); // 09:00 WIB
  final TimeOfDay _closingTimeWIB =
      TimeOfDay(hour: 20, minute: 0); // 20:00 WIB (Sesuai permintaan)

  // Offset zona waktu terhadap WIB (UTC+7)
  // Ini adalah perhitungan sederhana yang TIDAK mempertimbangkan Daylight Saving Time (DST)
  final Map<String, Duration> _timezoneOffsetsFromWIB = {
    'WIB': const Duration(hours: 0),
    'WITA': const Duration(hours: 1), // WIB + 1 jam
    'WIT': const Duration(hours: 2), // WIB + 2 jam
    'London': const Duration(hours: -7), // London (GMT) adalah WIB - 7 jam
  };

  // Fungsi untuk mendapatkan jam operasional terkonversi
  String _getOperatingHours(String timezoneName) {
    final Duration offset = _timezoneOffsetsFromWIB[timezoneName]!;

    final DateTime now = DateTime.now();
    final DateTime openingDateTimeWIB = DateTime(now.year, now.month, now.day,
        _openingTimeWIB.hour, _openingTimeWIB.minute);
    final DateTime closingDateTimeWIB = DateTime(now.year, now.month, now.day,
        _closingTimeWIB.hour, _closingTimeWIB.minute);

    final DateTime openingTimeConverted = openingDateTimeWIB.add(offset);
    final DateTime closingTimeConverted = closingDateTimeWIB.add(offset);

    final DateFormat formatter = DateFormat('HH:mm');
    String formattedOpen = formatter.format(openingTimeConverted);
    String formattedClose = formatter.format(closingTimeConverted);

    // Cek apakah toko sedang buka atau tutup di zona waktu ini
    final DateTime currentTimeInTargetZone =
        now.add(offset); // Waktu sekarang di zona target
    // Perbandingan harus dilakukan dengan memastikan hari yang sama jika melewati tengah malam
    final TimeOfDay currentTimeOfDay =
        TimeOfDay.fromDateTime(currentTimeInTargetZone);
    final TimeOfDay openingTimeOfDayConverted =
        TimeOfDay.fromDateTime(openingTimeConverted);
    final TimeOfDay closingTimeOfDayConverted =
        TimeOfDay.fromDateTime(closingTimeConverted);

    bool isOpen = false;
    if (openingTimeOfDayConverted.hour < closingTimeOfDayConverted.hour ||
        (openingTimeOfDayConverted.hour == closingTimeOfDayConverted.hour &&
            openingTimeOfDayConverted.minute <=
                closingTimeOfDayConverted.minute)) {
      // Kasus normal: buka dan tutup di hari yang sama
      isOpen = currentTimeOfDay.hour > openingTimeOfDayConverted.hour ||
          (currentTimeOfDay.hour == openingTimeOfDayConverted.hour &&
              currentTimeOfDay.minute >= openingTimeOfDayConverted.minute);
      isOpen = isOpen &&
          (currentTimeOfDay.hour < closingTimeOfDayConverted.hour ||
              (currentTimeOfDay.hour == closingTimeOfDayConverted.hour &&
                  currentTimeOfDay.minute < closingTimeOfDayConverted.minute));
    } else {
      // Kasus melewati tengah malam (misal buka jam 22:00, tutup jam 06:00)
      isOpen = currentTimeOfDay.hour > openingTimeOfDayConverted.hour ||
          (currentTimeOfDay.hour == openingTimeOfDayConverted.hour &&
              currentTimeOfDay.minute >= openingTimeOfDayConverted.minute) ||
          currentTimeOfDay.hour < closingTimeOfDayConverted.hour ||
          (currentTimeOfDay.hour == closingTimeOfDayConverted.hour &&
              currentTimeOfDay.minute < closingTimeOfDayConverted.minute);
    }

    return '$formattedOpen - $formattedClose ${isOpen ? "(Buka Sekarang)" : "(Tutup)"}';
  }

  // Fungsi untuk mendapatkan waktu saat ini di zona waktu tertentu
  String _getCurrentTimeInTimezone(String timezoneName) {
    final Duration offset = _timezoneOffsetsFromWIB[timezoneName]!;
    final DateTime now = DateTime.now();
    final DateTime currentTimeConverted = now.add(offset);
    return DateFormat('dd MMM, HH:mm').format(currentTimeConverted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Saran & Kesan")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian Info Jam Operasional
            Card(
              margin: const EdgeInsets.only(bottom: 20),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Jam Operasional Toko",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Toko kami beroperasi dari pukul ${_openingTimeWIB.format(context)} hingga ${_closingTimeWIB.format(context)} WIB.",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Waktu Operasional Terkonversi:",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildTimezoneInfoRow('WIB'),
                    _buildTimezoneInfoRow('WITA'),
                    _buildTimezoneInfoRow('WIT'),
                    _buildTimezoneInfoRow('London'),
                    const SizedBox(height: 8),
                    const Text(
                      "*Estimasi tanpa Daylight Saving Time (DST). Waktu diperbarui setiap detik.",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            // Bagian Konversi Waktu Saat Ini
            Card(
              margin: const EdgeInsets.only(bottom: 20),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Waktu Saat Ini (Periksa Zona Waktu Anda):",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "WIB: ${DateFormat('dd MMM, HH:mm').format(DateTime.now())}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: _selectedTimezone,
                      decoration: const InputDecoration(
                        labelText: "Konversi Waktu ke",
                        border: OutlineInputBorder(),
                      ),
                      items: _timezoneOffsetsFromWIB.keys
                          .where((key) => key != 'WIB')
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedTimezone = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Waktu di $_selectedTimezone: ${_getCurrentTimeInTimezone(_selectedTimezone)}",
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange),
                    ),
                  ],
                ),
              ),
            ),

            // Bagian Kesan dan Pesan Statis
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Kesan dan Pesan",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Halo pelanggan setia! Kami sangat senang Anda telah meluangkan waktu untuk mengunjungi toko aksesoris kami. Kami berkomitmen untuk menyediakan produk-produk berkualitas tinggi dan pengalaman berbelanja yang tak terlupakan.",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Setiap aksesoris di toko kami dipilih dengan cermat untuk memastikan Anda mendapatkan yang terbaik, baik dari segi gaya maupun kualitas. Kami percaya bahwa setiap detail kecil dapat membuat perbedaan besar.",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Kami selalu berupaya meningkatkan layanan kami. Jika Anda memiliki saran atau kesan, jangan ragu untuk menyampaikannya. Kepuasan Anda adalah prioritas utama kami!",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        "- Tim Toko Aksesoris",
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pembantu untuk menampilkan informasi jam operasional per zona waktu
  Widget _buildTimezoneInfoRow(String timezoneName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$timezoneName:",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            _getOperatingHours(timezoneName),
            style: const TextStyle(fontSize: 16, color: Colors.teal),
          ),
        ],
      ),
    );
  }
}
