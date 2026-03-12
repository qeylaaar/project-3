import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  // Biar status bar di atas ikutan gelap/transparan
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const PineappleApp());
}

class PineappleApp extends StatelessWidget {
  const PineappleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SPQC Monitoring',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1B12), // Background gelap kehijauan
        cardColor: const Color(0xFF1A2C21), // Warna kartu sensor
        primaryColor: const Color(0xFF00FF85), // Hijau Neon
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00FF85),
          brightness: Brightness.dark,
        ),
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Smart QC System', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: Color(0xFF00FF85), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Text('ESP32-CAM NODE 04 • ONLINE', 
                    style: TextStyle(fontSize: 10, color: Color(0xFF00FF85), letterSpacing: 1.2)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view_rounded, color: Color(0xFF00FF85)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text('LIVE CAMERA FEED', 
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
            const SizedBox(height: 10),
            
            // --- LIVE CAMERA CARD ---
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1550258987-190a2d41a8ba?q=80&w=1000&auto=format&fit=crop'), // Placeholder Nanas
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  // Status Badge
                  Positioned(
                    top: 15, left: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, size: 14, color: Colors.black),
                          SizedBox(width: 5),
                          Text('STATUS: RIPE', 
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  // Play Button Overlay
                  const Center(
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.play_arrow, color: Colors.white, size: 40),
                    ),
                  ),
                  // Bottom Bar (Confidence)
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('AI CONFIDENCE SCORE', style: TextStyle(fontSize: 10, color: Colors.white70)),
                          Text('98.4%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00FF85))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // --- SENSOR METRICS ---
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
              children: [
                _buildSensorCard('WEIGHT', '1.28', Icons.scale, 'kg'),
                _buildSensorCard('GAS/VOC', '42', Icons.air, 'ppm'),
                _buildSensorCard('INT. TEMP', '24.2', Icons.thermostat, '°C'),
              ],
            ),
            
            const SizedBox(height: 25),
            
            // --- ACTION BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF85),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                icon: const Icon(Icons.sensors),
                label: const Text('Trigger Scan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
            
            const SizedBox(height: 25),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('RECENT SCANS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text('VIEW ALL', style: TextStyle(fontSize: 12, color: Color(0xFF00FF85))),
              ],
            ),
            const SizedBox(height: 15),
            
            // --- HISTORY ITEM ---
            _buildHistoryItem('Grade A - Golden', 'Today, 14:18', '98%', '1.2kg'),
            _buildHistoryItem('Grade B - Green', 'Today, 14:05', '84%', '1.1kg'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard(String label, String value, IconData icon, String unit) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2C21),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF00FF85), size: 18),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                TextSpan(text: ' $unit', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String title, String time, String match, String weight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2C21),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.eco, color: Colors.amber, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$match Match', style: const TextStyle(color: Color(0xFF00FF85), fontWeight: FontWeight.bold, fontSize: 12)),
              Text(weight, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}