import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal dan waktu
import 'dart:async'; // Untuk Timer

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  String _selectedTimezone = 'WITA'; // Default zona waktu konversi
  Timer? _timer; // Timer untuk memperbarui waktu secara real-time

  // Waktu operasional toko di WIB (UTC+7)
  final TimeOfDay _openingTimeWIB = TimeOfDay(hour: 9, minute: 0); // 09:00 WIB
  final TimeOfDay _closingTimeWIB = TimeOfDay(hour: 20, minute: 0); // 20:00 WIB

  // Offset zona waktu terhadap WIB (UTC+7)
  // Ini adalah perhitungan sederhana yang TIDAK mempertimbangkan Daylight Saving Time (DST)
  final Map<String, Duration> _timezoneOffsetsFromWIB = {
    'WIB': const Duration(hours: 0),
    'WITA': const Duration(hours: 1), // WIB + 1 jam (UTC+8)
    'WIT': const Duration(hours: 2), // WIB + 2 jam (UTC+9)
    'London':
        const Duration(hours: -7), // London (GMT) adalah WIB - 7 jam (UTC+0)
    'Kuala Lumpur':
        const Duration(hours: 1), // Kuala Lumpur adalah WIB + 1 jam (UTC+8)
    'Manila': const Duration(hours: 1), // Manila adalah WIB + 1 jam (UTC+8)
    'Singapura':
        const Duration(hours: 1), // Singapura adalah WIB + 1 jam (UTC+8)
  };

  @override
  void initState() {
    super.initState();
    // Inisialisasi timer untuk memperbarui waktu setiap detik
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Waktu akan diperbarui saat setState dipanggil
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Pastikan timer dibatalkan saat widget dihapus
    super.dispose();
  }

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
    final DateTime currentTimeInTargetZone = now.add(offset);
    final TimeOfDay currentTimeOfDay =
        TimeOfDay.fromDateTime(currentTimeInTargetZone);
    final TimeOfDay openingTimeOfDayConverted =
        TimeOfDay.fromDateTime(openingTimeConverted);
    final TimeOfDay closingTimeOfDayConverted =
        TimeOfDay.fromDateTime(closingTimeConverted);

    bool isOpen = false;
    // Handle cases where closing time might be on the next day (e.g., 22:00 - 06:00)
    if (openingTimeConverted.isBefore(closingTimeConverted)) {
      // Normal operating hours within the same day
      isOpen = (currentTimeInTargetZone.isAfter(openingTimeConverted) ||
              currentTimeInTargetZone.isAtSameMomentAs(openingTimeConverted)) &&
          currentTimeInTargetZone.isBefore(closingTimeConverted);
    } else {
      // Operating hours span across midnight (e.g., 20:00 - 09:00 next day)
      isOpen = (currentTimeInTargetZone.isAfter(openingTimeConverted) ||
              currentTimeInTargetZone.isAtSameMomentAs(openingTimeConverted)) ||
          currentTimeInTargetZone.isBefore(closingTimeConverted);
    }

    return '$formattedOpen - $formattedClose ${isOpen ? "(Open Now)" : "(Closed)"}';
  }

  // Fungsi untuk mendapatkan waktu saat ini di zona waktu tertentu
  String _getCurrentTimeInTimezone(String timezoneName) {
    final Duration offset = _timezoneOffsetsFromWIB[timezoneName]!;
    final DateTime now = DateTime.now();
    final DateTime currentTimeConverted = now.add(offset);
    return DateFormat('HH:mm:ss, dd MMM').format(currentTimeConverted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light grey background
      appBar: AppBar(
        title: const Text(
          "Informasi & Saran Kesan",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey[900], // Dark grey app bar
        iconTheme: const IconThemeData(color: Colors.white), // White back icon
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Bagian Info Jam Operasional ---
            Card(
              margin: const EdgeInsets.only(bottom: 25),
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Jam Operasi Toko",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Toko kita beroperasi dari pukul ${_openingTimeWIB.format(context)} sampai ${_closingTimeWIB.format(context)} WIB.",
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Konversi ke Zona Lain",
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    _buildTimezoneInfoRow('WIB'),
                    _buildTimezoneInfoRow('WITA'),
                    _buildTimezoneInfoRow('WIT'),
                    _buildTimezoneInfoRow('London'),
                    _buildTimezoneInfoRow('Kuala Lumpur'),
                    _buildTimezoneInfoRow('Manila'),
                    _buildTimezoneInfoRow('Singapura'),
                    const SizedBox(height: 15),
                    Text(
                      "*Waktu diperbarui setiap detik.",
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),

            // --- Bagian Konversi Waktu Saat Ini ---
            Card(
              margin: const EdgeInsets.only(bottom: 25),
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Waktu Sekarang (Cek Zona Waktu Anda):",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "WIB: ${DateFormat('HH:mm:ss, dd MMM').format(DateTime.now())}",
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedTimezone,
                      decoration: InputDecoration(
                        labelText: "Konversi Waktu ke ",
                        labelStyle: TextStyle(color: Colors.grey[700]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[400]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Colors.black54, width: 2),
                        ),
                      ),
                      dropdownColor: Colors.white,
                      items: _timezoneOffsetsFromWIB.keys
                          .where((key) =>
                              key != 'WIB') // Exclude WIB from dropdown
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value,
                              style: const TextStyle(color: Colors.black87)),
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
                    const SizedBox(height: 15),
                    Text(
                      "Waktu di $_selectedTimezone: ${_getCurrentTimeInTimezone(_selectedTimezone)}",
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              Colors.black), // Strong black for converted time
                    ),
                  ],
                ),
              ),
            ),

            // --- Bagian Kesan dan Pesan Statis ---
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Kesan & Pesan",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Kesan saya terhadap mata kuliah ini, di bawah arahan Bapak Bagus Muhammad Akbar, S.ST., M.Kom., adalah sebuah petualangan yang mengasyikkan sekaligus mengasah kemampuan. Setiap 'pusing tujuh keliling' yang kami alami dalam eksplorasi mobile justru menjadi penempa, membentuk kami dengan pengalaman yang tak ternilai harganya. Ini adalah jejak digital yang tak akan mudah terhapus dari memori. Semoga jejak inovasi ini senantiasa menginspirasi angkatan-angkatan selanjutnya ya Pak!",
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Harapan terbesar kami adalah agar segala tetes keringat dan dedikasi yang telah kami curahkan , terbalaskan pada nilai ya pak hehe dan tentunya perjalanan karier di masa depan juga, dapat berbalas manis dan menjadi pijakan menuju kesuksesan.",
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 15),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        "- Owner Accessories Store, Jagad Damai",
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600]),
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
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87),
          ),
          Text(
            _getOperatingHours(timezoneName),
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black), // Changed to black for monochromatic
          ),
        ],
      ),
    );
  }
}
