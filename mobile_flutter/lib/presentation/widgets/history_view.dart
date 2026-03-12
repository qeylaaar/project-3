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
    return Column(
      children: records.map((record) => _buildHistoryItem(record)).toList(),
    );
  }

  Widget _buildHistoryItem(HistoryRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: record.isError ? Colors.orange.withOpacity(0.2) : AppTheme.accentNeonGreen.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              record.isError ? Icons.warning_amber_rounded : Icons.check_circle,
              color: record.isError ? Colors.amber : AppTheme.accentNeonGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Text(record.time, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Text(
            record.badgeText, 
            style: TextStyle(
              color: record.isError ? Colors.amber : Colors.white, 
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
