import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../presentation/widgets/history_view.dart';

class QcStateProvider extends ChangeNotifier {
  // IP Laptop kamu - Pastikan port 8000 sesuai artisan serve
  final String baseUrl = "http://192.168.137.1:8000/api";

  // State variables untuk Dashboard
  bool isLedOn = true;
  bool isScanning = false;
  
  double weight = 0.0;
  double voc = 0.0;
  double temperature = 0.0;
  double humidity = 0.0; // Ini bisa di-mock atau ambil dari gas_value
  
  String aiStatus = 'WAITING...';
  double confidenceScore = 0.0;
  
  // Count variables
  int ripeCount = 0;
  int halfRipeCount = 0;
  int unripeCount = 0;
  
  Timer? _pollingTimer;
  
  // List History untuk UI
  List<HistoryRecord> historyLogs = [];

  QcStateProvider() {
    // Jalankan fetch pertama kali
    fetchHistoryData();
    // Mulai polling setiap 3 detik agar sinkron dengan ESP32 & Laptop
    _startPolling();
  }

  // Fungsi utama untuk ambil data dari Laravel
  Future<void> fetchHistoryData() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/pineapple/history'));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        
        if (data.isNotEmpty) {
          // 1. Update History List
          historyLogs = data.map((item) {
            String statusRaw = item['status'] ?? 'UNKNOWN';
            String gradeText = "";
            bool isError = false;

            // Mapping status database ke UI Flutter
            if (statusRaw == 'RIPE') {
              gradeText = "Grade A - Matang";
            } else if (statusRaw == 'HALF_RIPE') {
              gradeText = "Grade B - Setengah";
            } else {
              gradeText = "Grade C - Mentah";
              isError = true;
            }

            return HistoryRecord(
              title: gradeText,
              time: item['created_at'].toString().substring(11, 16), // Ambil Jam:Menit
              subtitle: 'Confidence: ${item['confidence_score']}%',
              badgeText: '${item['confidence_score']}% Match',
              isError: isError,
            );
          }).toList();

          // 2. Update Dashboard dengan data scan TERBARU (index 0)
          var latest = data.first;
          aiStatus = latest['status'] == 'RIPE' ? 'MATANG' : (latest['status'] == 'HALF_RIPE' ? 'SETENGAH' : 'MENTAH');
          confidenceScore = double.tryParse(latest['confidence_score'].toString()) ?? 0.0;
          weight = double.tryParse(latest['weight'].toString()) ?? 0.0;
          voc = double.tryParse(latest['gas_value'].toString()) ?? 0.0;
          temperature = double.tryParse(latest['temperature'].toString()) ?? 0.0;
          humidity = 65.0; // Mock karena di migration belum ada humidity

          // 3. Update Counts
          ripeCount = data.where((item) => item['status'] == 'RIPE').length;
          halfRipeCount = data.where((item) => item['status'] == 'HALF_RIPE').length;
          unripeCount = data.where((item) => item['status'] == 'UNRIPE' || (item['status'] != 'RIPE' && item['status'] != 'HALF_RIPE')).length;
        }
        
        notifyListeners(); // Render ulang UI Flutter
      }
    } catch (e) {
      print("Error Fetching Data: $e");
    }
  }

  void _startPolling() {
    // Polling setiap 3 detik
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      fetchHistoryData();
    });
  }

  void toggleLed(bool val) {
    isLedOn = val;
    notifyListeners();
  }

  // Fungsi kalau kamu mau trigger scan manual dari tombol di Flutter
  Future<void> triggerScan() async {
    if (isScanning) return;
    
    isScanning = true;
    notifyListeners();
    
    try {
      // Simulasi trigger ke Laravel (misal default ke Grade A / status 1)
      final response = await http.get(Uri.parse('$baseUrl/nanas/status?status=1'));
      if (response.statusCode == 200) {
        await fetchHistoryData();
      }
    } catch (e) {
      aiStatus = 'CONNECTION ERROR';
    } finally {
      isScanning = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}