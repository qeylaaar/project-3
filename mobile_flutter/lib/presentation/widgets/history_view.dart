import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class HistoryRecord {
  final int id;
  final String title;
  final String time;
  final String subtitle;
  final String badgeText;
  final bool isError;
  final String? recommendation;
  final double? tss; // <--- Tambahkan ini

  HistoryRecord({
    required this.id,
    required this.title,
    required this.time,
    required this.subtitle,
    required this.badgeText,
    this.isError = false,
    this.recommendation,
    this.tss, // <--- Tambahkan ini
  });
}

class HistoryView extends StatelessWidget {
  final List<HistoryRecord> records;
  final Function(HistoryRecord) onTapRecord;

  const HistoryView({super.key, required this.records, required this.onTapRecord});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        
        // LOCK CLICK: Jika sudah ada rekomendasi, onTap dimatikan (null)
        return InkWell(
          onTap: record.recommendation == null ? () => onTapRecord(record) : null,
          borderRadius: BorderRadius.circular(12),
          child: _buildHistoryItem(record),
        );
      },
    );
  }

  Widget _buildHistoryItem(HistoryRecord record) {
    bool hasRec = record.recommendation != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        // Kasih border neon tipis kalau sudah ada rekomendasi biar keren
        border: Border.all(
          color: hasRec ? AppTheme.accentNeonGreen.withOpacity(0.3) : (record.isError ? Colors.red.withOpacity(0.3) : Colors.transparent),
        ),
      ),
      child: Row(
        children: [
          _buildIcon(record.isError),
          const SizedBox(width: 16),
          Expanded(child: _buildInfo(record)),
          _buildBadge(record),
        ],
      ),
    );
  }

  Widget _buildIcon(bool isError) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isError ? Colors.red.withOpacity(0.2) : AppTheme.accentNeonGreen.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isError ? Icons.cancel_outlined : Icons.check_circle,
        color: isError ? Colors.redAccent : AppTheme.accentNeonGreen,
        size: 20,
      ),
    );
  }

  Widget _buildInfo(HistoryRecord record) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(record.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
        const SizedBox(height: 4),
        Text("Jam: ${record.time}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text(record.subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        
        if (record.recommendation != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentNeonGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "Rekomendasi: ${record.recommendation}",
              style: const TextStyle(color: AppTheme.accentNeonGreen, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ]
      ],
    );
  }

Widget _buildBadge(HistoryRecord record) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      // Badge Match % yang sudah ada
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
            fontSize: 11
          )
        ),
      ),
      
      // Tampilkan Nilai TSS jika sudah diinput
      if (record.tss != null) ...[
        const SizedBox(height: 6),
        Text(
          "${record.tss!.toStringAsFixed(1)} °Brix",
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5
          ),
        ),
      ],
    ],
  );
}
}