import 'dart:async';
import 'package:flutter/material.dart';
import '../services/laravel_api_service.dart';
import '../presentation/widgets/history_view.dart';

class QcStateProvider extends ChangeNotifier {
  final LaravelApiService _apiService = LaravelApiService();
  
  // State variables
  bool isLedOn = true;
  bool isScanning = false;
  
  double weight = 1.28;
  double voc = 42.0;
  double temperature = 24.2;
  double humidity = 68.0;
  
  String aiStatus = 'INITIALIZING...';
  double confidenceScore = 0.0;
  
  Timer? _pollingTimer;
  
  List<HistoryRecord> historyLogs = [
     HistoryRecord(title: 'Grade B - Green', time: 'Today, 14:05', subtitle: '', badgeText: '84% Match'),
  ];

  QcStateProvider() {
    // Start polling sensors
    _startPolling();
  }

  void toggleLed(bool val) {
    isLedOn = val;
    notifyListeners();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!isScanning) {
        try {
          final data = await _apiService.fetchSensorData();
          weight = data['weight'];
          voc = data['voc'];
          temperature = data['temperature'];
          humidity = data['humidity'];
          notifyListeners();
        } catch (e) {
          // Handle error
        }
      }
    });
  }

  Future<void> triggerScan() async {
    if (isScanning) return;
    
    isScanning = true;
    notifyListeners();
    
    try {
      // Initiates the complex workflow: Flutter -> Laravel API -> ESP32 -> Laravel -> Python AI -> Laravel -> Flutter
      final result = await _apiService.triggerScan();
      
      aiStatus = result['ai_status'];
      confidenceScore = result['confidence_score'];
      
      // Prepend to history log
      historyLogs.insert(0, HistoryRecord(
        title: '${result['grade']} - Scanned',
        time: 'Just now',
        subtitle: '',
        badgeText: '${confidenceScore.toStringAsFixed(1)}% Match',
      ));
      
    } catch (e) {
      aiStatus = 'ERROR DETECTED';
      historyLogs.insert(0, HistoryRecord(
        title: 'Scan Failed',
        time: 'Just now',
        subtitle: '',
        badgeText: 'Alert',
        isError: true,
      ));
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
