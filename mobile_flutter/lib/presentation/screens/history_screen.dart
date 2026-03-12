import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/qc_state_provider.dart';
import '../../theme/app_theme.dart';
import '../widgets/history_view.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Scan History', style: TextStyle(color: AppTheme.accentNeonGreen)),
        backgroundColor: AppTheme.primaryBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.accentNeonGreen),
      ),
      body: Consumer<QcStateProvider>(
        builder: (context, provider, child) {
          if (provider.historyLogs.isEmpty) {
            return const Center(
              child: Text(
                'No scan history found.',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: HistoryView(records: provider.historyLogs),
          );
        },
      ),
    );
  }
}
