import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/qc_state_provider.dart';
import '../../theme/app_theme.dart';
import '../widgets/history_view.dart';
import '../widgets/custom_bottom_nav.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('All Scan History', style: TextStyle(color: AppTheme.accentNeonGreen, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.accentNeonGreen),
      ),
      body: RefreshIndicator(
        color: AppTheme.accentNeonGreen,
        onRefresh: () => context.read<QcStateProvider>().fetchHistoryData(),
        child: Consumer<QcStateProvider>(
          builder: (context, provider, child) {
            if (provider.historyLogs.isEmpty) {
              return ListView( // ListView biar RefreshIndicator tetep jalan walau kosong
                children: const [
                  SizedBox(height: 100),
                  Center(
                    child: Text(
                      'No scan history found.\nTry to scan from the dashboard!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ],
              );
            }
            
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(), // Biar RefreshIndicator aktif
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: HistoryView(records: provider.historyLogs),
            );
          },
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
    );
  }
}