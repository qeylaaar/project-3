import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/qc_state_provider.dart';
import '../../theme/app_theme.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/live_feed_layer.dart';
import '../widgets/metrics_grid.dart';
import '../widgets/control_panel.dart';
import '../widgets/history_view.dart';
import 'history_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Smart QC System', 
                style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 18)),
            Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.accentNeonGreen, 
                    shape: BoxShape.circle
                  ),
                ),
                const SizedBox(width: 6),
                const Text('ESP32-CAM NODE 04 • ONLINE', 
                    style: TextStyle(fontSize: 10, color: AppTheme.accentNeonGreen, letterSpacing: 1.2)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view_rounded, color: AppTheme.accentNeonGreen),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<QcStateProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text('LIVE CAMERA FEED', 
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                const SizedBox(height: 10),
                
                // Live Camera Widget
                LiveFeedLayer(
                  streamUrl: 'http://192.168.1.100:81/stream', // Placeholder URL for now
                  isRunning: true,
                  aiStatus: provider.aiStatus,
                  confidenceScore: provider.confidenceScore,
                ),
                const SizedBox(height: 20),
                
                // Sensor Metrics Widget
                MetricsGrid(
                  weight: provider.weight,
                  voc: provider.voc,
                  temperature: provider.temperature,
                  humidity: provider.humidity,
                ),
                
                const SizedBox(height: 25),
                
                // Controls Widget
                ControlPanel(
                  isScanning: provider.isScanning,
                  isLedOn: provider.isLedOn,
                  onTriggerScan: () {
                    provider.triggerScan();
                  },
                  onLedToggled: (val) {
                    provider.toggleLed(val);
                  },
                ),
                
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('RECENT SCANS', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HistoryScreen()),
                        );
                      },
                      child: const Text('VIEW ALL', style: TextStyle(fontSize: 12, color: AppTheme.accentNeonGreen)),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                
                // History Log Widget
                HistoryView(
                  records: provider.historyLogs,
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNav(),
    );
  }
}
