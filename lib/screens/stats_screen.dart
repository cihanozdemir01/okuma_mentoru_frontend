import 'package:flutter/material.dart';
import 'package:okuma_mentoru_mobil/models/home_screen_data.dart';
import 'package:okuma_mentoru_mobil/services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final ApiService apiService = ApiService();

  // Seçimleri tutan state'ler
  String _selectedMetric = 'page_count'; // 'page_count' veya 'book_count'
  String _selectedGroupBy = 'month';   // 'day', 'week', 'month'
  
  Future<List<SummaryData>>? summaryFuture;
  Future<IstatistiklerData>? statsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      statsFuture = apiService.getHomeScreenData().then((data) => data.istatistikler);
      summaryFuture = apiService.getSummary(
        metric: _selectedMetric,
        groupBy: _selectedGroupBy,
      );
    });
  }

  Future<void> _handleRefresh() async {
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Okuma Haritam"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- KONTROL PANELİ ---
            _buildControlPanel(),
            const SizedBox(height: 24),
            
            // --- DİNAMİK GRAFİK ---
            _buildDynamicChart(),
            
            const Divider(height: 40, thickness: 1),
            
            // --- GENEL İSTATİSTİKLER ---
            const Text("Genel İstatistikler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildOverallStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Metrik Seçimi (Sayfa/Kitap)
            SegmentedButton<String>(
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: Colors.deepPurple.shade100,
                side: BorderSide(color: Colors.deepPurple.shade100),
              ),
              segments: const [
                ButtonSegment(value: 'page_count', label: Text('Sayfa'), icon: Icon(Icons.pages_outlined)),
                ButtonSegment(value: 'book_count', label: Text('Kitap'), icon: Icon(Icons.book_outlined)),
              ],
              selected: {_selectedMetric},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _selectedMetric = newSelection.first;
                  _loadData();
                });
              },
            ),
            const SizedBox(height: 8),
            // Zaman Aralığı Seçimi (Gün/Hafta/Ay)
            SegmentedButton<String>(
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: Colors.deepPurple.shade100,
                side: BorderSide(color: Colors.deepPurple.shade100),
              ),
              segments: const [
                ButtonSegment(value: 'day', label: Text('Günlük')),
                ButtonSegment(value: 'week', label: Text('Haftalık')),
                ButtonSegment(value: 'month', label: Text('Aylık')),
              ],
              selected: {_selectedGroupBy},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _selectedGroupBy = newSelection.first;
                  _loadData();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicChart() {
    return FutureBuilder<List<SummaryData>>(
      future: summaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return SizedBox(height: 250, child: Center(child: Text("Grafik verisi yüklenemedi.")));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(height: 250, child: Center(child: Text("Bu periyotta gösterilecek veri yok.")));
        }
        
        final data = snapshot.data!;
        double maxY = 0;
        if (data.isNotEmpty) {
          maxY = data.map((d) => d.value).reduce((a, b) => a > b ? a : b).toDouble();
        }
        if (maxY == 0) maxY = 5;

        return SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY * 1.2, // Çubuğun üstünde biraz boşluk bırak
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.deepPurple,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final item = data[group.x.toInt()];
                    String periodText;
                    if (_selectedGroupBy == 'day') {
                      periodText = DateFormat('d MMMM yyyy', 'tr_TR').format(item.period);
                    } else if (_selectedGroupBy == 'week') {
                      periodText = "${DateFormat('d MMM', 'tr_TR').format(item.period)} Haftası";
                    } else {
                      periodText = DateFormat('MMMM yyyy', 'tr_TR').format(item.period);
                    }
                    String valueText = _selectedMetric == 'page_count' ? "${rod.toY.toInt()} Sayfa" : "${rod.toY.toInt()} Kitap";
                    return BarTooltipItem('$periodText\n$valueText', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value.toInt() >= data.length) return const SizedBox.shrink();
                      final item = data[value.toInt()];
                      String text;
                      if (_selectedGroupBy == 'day') {
                        text = DateFormat('d', 'tr_TR').format(item.period);
                      } else if (_selectedGroupBy == 'week') {
                        text = DateFormat('d/M', 'tr_TR').format(item.period);
                      } else {
                        text = DateFormat('MMM', 'tr_TR').format(item.period);
                      }
                      return Padding(padding: const EdgeInsets.only(top: 6.0), child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)));
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: false),
              barGroups: data.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.value.toDouble(),
                      gradient: LinearGradient(
                        colors: _selectedMetric == 'page_count'
                          ? [Colors.lightBlue, Colors.blueAccent]
                          : [Colors.lightGreen, Colors.green],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      width: 16,
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverallStats() {
    return FutureBuilder<IstatistiklerData>(
      future: statsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final istatistikler = snapshot.data!;
        return Column(
          children: [
            _buildStatCard(
              icon: Icons.check_circle_outline,
              value: istatistikler.bitirilenKitapSayisi.toString(),
              label: "Toplam Bitirilen Kitap",
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              icon: Icons.menu_book_outlined,
              value: istatistikler.toplamOkunanSayfa.toString(),
              label: "Toplam Okunan Sayfa",
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              icon: Icons.local_fire_department_outlined,
              value: istatistikler.gunlukSeri.toString(),
              label: "Günlük Okuma Serisi",
              color: Colors.orange,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}