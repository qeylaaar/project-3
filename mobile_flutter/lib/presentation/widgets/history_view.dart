import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class HistoryRecord {
  final String title;
  final String time;
  final String subtitle;
  final String badgeText;
  final bool isError;

  HistoryRecord({
    required this.title,
    required this.time,
    required this.subtitle,
    required this.badgeText,
    this.isError = false,
  });
}

class HistoryView extends StatelessWidget {
  final List<HistoryRecord> records;

  const HistoryView({
    super.key,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    // Pake ListView.builder biar lebih enteng performanya
    return ListView.builder(
      shrinkWrap: true, // Biar bisa masuk di dalam Column/Scroll lain
      physics: const NeverScrollableScrollPhysics(), 
      itemCount: records.length,
      itemBuilder: (context, index) {
        return _buildHistoryItem(records[index]);
      },
    );
  }

  Widget _buildHistoryItem(HistoryRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: record.isError ? Colors.red.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: record.isError ? Colors.red.withOpacity(0.2) : AppTheme.accentNeonGreen.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              record.isError ? Icons.cancel_outlined : Icons.check_circle,
              color: record.isError ? Colors.redAccent : AppTheme.accentNeonGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                const SizedBox(height: 4),
                Text("Jam: ${record.time}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                Text(record.subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: record.isError ? Colors.red.withOpacity(0.1) : AppTheme.accentNeonGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              record.badgeText, 
              style: TextStyle(
                color: record.isError ? Colors.redAccent : AppTheme.accentNeonGreen, 
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}