import 'package:flutter/material.dart';
import 'package:okuma_mentoru_mobil/models/home_screen_data.dart';
import 'package:okuma_mentoru_mobil/services/api_service.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:intl/intl.dart';
import 'package:okuma_mentoru_mobil/utils/snackbar_helper.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final ApiService apiService = ApiService();

  // Değişkenleri nullable (?) olarak tanımlıyoruz.
  Future<IstatistiklerData>? statsFuture;
  Future<List<MonthlySummary>>? summaryFuture;
  Future<Map<DateTime, int>>? heatmapFuture;

  @override
  void initState() {
    super.initState();
    // Veri yüklemeyi initState içinde başlatıyoruz.
    _loadData();
  }

  // Bu metot, API isteklerini başlatır.
  void _loadData() {
    statsFuture = apiService.getHomeScreenData().then((data) => data.istatistikler);
    summaryFuture = apiService.getMonthlySummary();
    heatmapFuture = apiService.getHeatmapData().then((data) {
      print("--- HEATMAP VERİSİ GELDİ ---");
      print(data);
      print("--------------------------");
      return data.map((key, value) => MapEntry(DateTime.parse(key), value));
    });
  }

  // RefreshIndicator tarafından çağrılacak metot.
  // setState kullanarak ekranın yeniden çizilmesini sağlar.
  Future<void> _handleRefresh() async {
    setState(() {
      _loadData();
    });
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
            // --- HEATMAP BÖLÜMÜ ---
            const Text("Okuma Takvimi (Son 1 Yıl)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            FutureBuilder<Map<DateTime, int>>(
              future: heatmapFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
                } else if (snapshot.hasError) {
                  return SizedBox(height: 160, child: Center(child: Text('Takvim verisi yüklenemedi: ${snapshot.error}')));
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: HeatMapCalendar(
                        datasets: snapshot.data,
                        colorsets: const {
                          1: Color(0xFFD8BFD8), 
                          10: Color(0xFFC8A2C8),
                          20: Color(0xFFB886B8),
                          30: Color(0xFFA86AA8),
                          50: Colors.deepPurple,
                        },
                        onClick: (date) {
                          final count = snapshot.data![DateTime(date.year, date.month, date.day)] ?? 0;
                          final formattedDate = DateFormat('d MMMM yyyy', 'tr_TR').format(date);
                          SnackBarHelper.showInfo(context, '$formattedDate: $count sayfa okundu.');
                        },
                        monthFontSize: 14,
                        weekTextColor: Colors.grey,
                        defaultColor: Colors.grey.shade200,
                        textColor: Colors.black,
                      ),
                    ),
                  );
                } else {
                  return const SizedBox(
                    height: 160,
                    child: Center(
                      child: Text("Okuma aktivitesi bulunamadı.", style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }
              },
            ),
            const Divider(height: 40),

            // --- AYLIK GRAFİK BÖLÜMÜ ---
            const Text("Aylık Kitap Bitirme Grafiği", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            FutureBuilder<List<MonthlySummary>>(
              future: summaryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                } else if (snapshot.hasError) {
                  return SizedBox(height: 200, child: Center(child: Text('Grafik verisi yüklenemedi.')));
                } else if (snapshot.hasData) {
                  final bool hasDataToShow = snapshot.data!.any((d) => d.count > 0);
                  if (!hasDataToShow) {
                    return const SizedBox(
                      height: 200,
                      child: Center(
                        child: Text("Bu yıl henüz hiç kitap bitirmemişsin.", style: TextStyle(color: Colors.grey)),
                      ),
                    );
                  }
                  return SizedBox(
                    height: 200,
                    child: _buildBarChart(snapshot.data!),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const Divider(height: 40),

            // --- GENEL İSTATİSTİKLER BÖLÜMÜ ---
            const Text("Genel İstatistikler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            FutureBuilder<IstatistiklerData>(
              future: statsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('İstatistikler yüklenemedi.'));
                } else if (snapshot.hasData) {
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
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
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

  Widget _buildBarChart(List<MonthlySummary> data) {
    double maxY = data.map((d) => d.count).reduce((a, b) => a > b ? a : b).toDouble();
    if (maxY == 0) maxY = 5;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY + 1,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.deepPurple,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String month = data[group.x.toInt()].month;
              String count = rod.toY.toInt().toString();
              return BarTooltipItem(
                '$month\n$count Kitap',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final String monthName = data[value.toInt()].month;
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(monthName.substring(0, 1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                );
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
          int index = entry.key;
          MonthlySummary summary = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: summary.count.toDouble(),
                gradient: LinearGradient(
                  colors: [Colors.purple, Colors.deepPurple.shade300],
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
    );
  }
}