import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/qc_state_provider.dart';
import '../../theme/app_theme.dart';
import '../widgets/custom_bottom_nav.dart';
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
        title: const Text('Smart QC Analytics', 
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.accentNeonGreen), 
            onPressed: () {}
          ),
        ],
      ),
      body: Consumer<QcStateProvider>(
        builder: (context, provider, child) {
          // Hitung persentase kualitas buat ngisi kekosongan
          double total = (provider.ripeCount + provider.unripeCount).toDouble();
          double qualityRate = total > 0 ? (provider.ripeCount / total) * 100 : 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ANALYTICS CARD (Gantiin kekosongan biar mewah)
                _buildAnalyticsCard(context, qualityRate, provider.ripeCount, provider.unripeCount),
                
                const SizedBox(height: 30),

                // 2. RECENT SCANS SECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('RECENT SCANS', 
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9))),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HistoryScreen()),
                        );
                      },
                      child: const Text('VIEW ALL', 
                        style: TextStyle(fontSize: 12, color: AppTheme.accentNeonGreen, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. HISTORY LIST (Ditambahin limit biar pas di layar)
                provider.historyLogs.isEmpty 
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Text("No scan data available", style: TextStyle(color: Colors.white38)),
                      ),
                    )
                  : HistoryView(
                      records: provider.historyLogs,
                      onTapRecord: (record) {
                        if (record.recommendation == null) {
                          _showTssInputSheet(context, record, provider);
                        }
                      },
                    ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }

  // Widget baru buat gantiin kekosongan: Analytics Card
  Widget _buildAnalyticsCard(BuildContext context, double rate, int ripe, int unripe) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accentNeonGreen.withOpacity(0.1)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.cardBackground, Colors.black.withOpacity(0.5)],
        ),
      ),
      child: Column(
        children: [
          const Text("OVERALL QUALITY RATE", 
            style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Text("${rate.toStringAsFixed(1)}%", 
            style: const TextStyle(color: AppTheme.accentNeonGreen, fontSize: 42, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          // Progress Bar Kualitas
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: rate / 100,
              backgroundColor: Colors.white10,
              color: AppTheme.accentNeonGreen,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("MATANG", ripe.toString(), AppTheme.accentNeonGreen),
              Container(width: 1, height: 30, color: Colors.white10),
              _buildStatItem("MENTAH", unripe.toString(), Colors.redAccent),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showTssInputSheet(BuildContext context, HistoryRecord record, QcStateProvider provider) {
    TextEditingController tssController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 20, right: 20, top: 20
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("INPUT NILAI TSS (°Brix)", style: TextStyle(color: AppTheme.accentNeonGreen, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: tssController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(filled: true, fillColor: Colors.black26, hintText: "Example: 12.5"),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentNeonGreen),
                onPressed: () async {
                  if (tssController.text.isNotEmpty) {
                    final messenger = ScaffoldMessenger.of(context);
                    await provider.updateTss(record.id, double.parse(tssController.text));
                    if (context.mounted) Navigator.pop(context);
                    messenger.showSnackBar(const SnackBar(content: Text("Success!"), backgroundColor: AppTheme.accentNeonGreen));
                  }
                },
                child: const Text("SIMPAN", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}