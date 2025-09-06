// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:okuma_mentoru_mobil/models/kitap.dart';
import 'package:okuma_mentoru_mobil/models/home_screen_data.dart';
import 'package:okuma_mentoru_mobil/screens/add_book_screen.dart';
import 'package:okuma_mentoru_mobil/screens/book_detail_screen.dart';
import 'package:okuma_mentoru_mobil/services/api_service.dart';
import 'package:okuma_mentoru_mobil/widgets/kitap_karti.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService apiService = ApiService();
  late Future<HomeScreenData> homeScreenDataFuture;
  
  @override
  void initState() {
    super.initState();
    // Uygulama ilk açıldığında verileri çekmek için bu metodu çağır.
    _refreshHomeScreenData();
  }

  void _refreshHomeScreenData() {
    setState(() {
      homeScreenDataFuture = apiService.getHomeScreenData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Okuma Listem'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'ŞU AN OKUDUKLARIM'),
              Tab(text: 'BİTİRDİKLERİM'),
            ],
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
            indicatorColor: Colors.white,
            indicatorWeight: 3.0,
          ),
        ),
        body: TabBarView(
          children: [
            _buildKitapListesi('okunuyor'),
            _buildKitapListesi('bitti'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddBookScreen()),
            );
            _refreshHomeScreenData();
          },
          tooltip: 'Yeni Kitap Ekle',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildKitapListesi(String status) {
    return FutureBuilder<HomeScreenData>(
      future: homeScreenDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
        } else {
          final tumKitaplar = snapshot.data!.kitaplar;
          final istatistikler = snapshot.data!.istatistikler;

          final filtrelenmisKitaplar = tumKitaplar.where((kitap) => kitap.status == status).toList();

          return Column(
            children: [
              _buildIstatistikKarti(istatistikler),

              if (filtrelenmisKitaplar.isEmpty)
                Expanded(
                  child: _buildBosEkran(),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: filtrelenmisKitaplar.length,
                    itemBuilder: (BuildContext context, int index) {
                      final kitap = filtrelenmisKitaplar[index];
                      return InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookDetailScreen(kitap: kitap),
                            ),
                          );
                          _refreshHomeScreenData();
                        },
                        child: KitapKarti(kitap: kitap),
                      );
                    },
                  ),
                ),
            ],
          );
        }
      },
    );
  }

  Widget _buildIstatistikKarti(IstatistiklerData istatistikler) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildIstatistikElemani(
              icon: Icons.check_circle,
              sayi: istatistikler.bitirilenKitapSayisi.toString(),
              etiket: 'Bitirilen Kitap',
              renk: Colors.green,
            ),
            _buildIstatistikElemani(
              icon: Icons.menu_book,
              sayi: istatistikler.toplamOkunanSayfa.toString(),
              etiket: 'Toplam Sayfa',
              renk: Colors.blue,
            ),
            // GÜNLÜK SERİ
            _buildIstatistikElemani(
              icon: Icons.local_fire_department,
              sayi: istatistikler.gunlukSeri.toString(),
              etiket: 'Günlük Seri',
              renk: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIstatistikElemani({
    required IconData icon,
    required String sayi,
    required String etiket,
    required Color renk,
  }) {
    return Column(
      children: [
        Icon(icon, size: 30, color: renk),
        const SizedBox(height: 8),
        Text(
          sayi,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          etiket,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildBosEkran() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Bu rafta henüz kitap yok.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sağ alttaki (+) butonuna basarak okumak istediğin bir kitabı ekleyebilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}