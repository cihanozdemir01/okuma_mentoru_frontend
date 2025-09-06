// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:okuma_mentoru_mobil/models/kitap.dart';
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
  late Future<List<Kitap>> kitaplarFuture;

  @override
  void initState() {
    super.initState();
    _refreshKitaplar();
  }

  void _refreshKitaplar() {
    setState(() {
      kitaplarFuture = apiService.getKitaplar();
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- YENİ WIDGET: DefaultTabController ---
    // Bu widget, altındaki TabBar ve TabBarView'ın senkronize çalışmasını sağlar.
    return DefaultTabController(
      length: 2, // Toplam sekme sayısını belirtiyoruz.
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Okuma Listem'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          // --- YENİ WIDGET: TabBar ---
          // AppBar'ın altına sekmeleri yerleştiriyoruz.
          bottom: const TabBar(
          // --- YENİ EKLENEN SATIRLAR ---
          labelColor: Colors.white, // Seçili olan sekmenin metin rengi
          unselectedLabelColor: Colors.white70, // Seçili olmayan sekmelerin metin rengi (biraz soluk beyaz)
          // --- YENİ SATIRLARIN SONU ---
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
        // --- YENİ WIDGET: TabBarView ---
        // Her bir sekmeye karşılık gelen içeriği burada tanımlıyoruz.
        body: TabBarView(
          children: [
            // "ŞU AN OKUDUKLARIM" sekmesinin içeriği
            _buildKitapListesi('okunuyor'),
            
            // "BİTİRDİKLERİM" sekmesinin içeriği
            _buildKitapListesi('bitti'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddBookScreen()),
            );
            _refreshKitaplar();
          },
          tooltip: 'Yeni Kitap Ekle',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // --- YENİ METOT: _buildKitapListesi ---
  // Kod tekrarını önlemek için, kitap listesini oluşturan FutureBuilder'ı
  // ayrı bir metoda taşıdık. Bu metot, hangi statüdeki kitapları
  // listeleyeceğini bir parametre olarak alır.
  Widget _buildKitapListesi(String status) {
    return FutureBuilder<List<Kitap>>(
      future: kitaplarFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // İstatistik Kartı (Boş Durum) ---
          // Hiç kitap yokken bile İstatistik Kartı görünsün diye Column içine alıyoruz.
          return Column(
            children: [
              _buildIstatistikKarti(0, 0), // Hiç kitap yoksa değerler sıfırdır.
              const Expanded(
                child: Center(child: Text('Bu listede henüz kitap yok.')),
              ),
            ],
          );
         } else {
          final tumKitaplar = snapshot.data!;
          // İstatistikleri tüm kitaplar üzerinden hesapla
          final int bitirilenKitapSayisi = tumKitaplar.where((k) => k.status == 'bitti').length;
          final int toplamOkunanSayfa = tumKitaplar.fold(0, (sum, k) => sum + k.currentPage);

          // Mevcut sekme için kitapları filtrele
          final filtrelenmisKitaplar = tumKitaplar.where((kitap) => kitap.status == status).toList();

          // --- YENİ WIDGET YAPISI: Column ---
          // Önce istatistik kartını, sonra listeyi göstermek için Column kullanıyoruz.
          return Column(
            children: [
              // Hesaplanan dinamik değerlerle istatistik kartını oluştur.
              _buildIstatistikKarti(bitirilenKitapSayisi, toplamOkunanSayfa),

              // Eğer filtrelenmiş liste boşsa mesaj göster.
              if (filtrelenmisKitaplar.isEmpty)
                const Expanded(
                  child: Center(child: Text('Bu listede henüz kitap yok.')),
                )
              // Eğer doluysa, listeyi göster.
              else
                // Expanded, Column içinde ListView'ın ne kadar yer kaplayacağını
                // bilmesini ve hata vermemesini sağlar.
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
                          _refreshKitaplar();
                        },
                        child: KitapKarti(kitap: kitap),
                      );
                    },
                  ),
                ),
            ],
          );
          // --- YENİ YAPININ SONU ---
        }
      },
    );
  }

  // --- YENİ EKLENEN METOT: _buildIstatistikKarti ---
  // İstatistik kartını oluşturan, yeniden kullanılabilir widget metodu.
  Widget _buildIstatistikKarti(int bitirilenKitapSayisi, int toplamOkunanSayfa) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround, // Elemanları aralıklı dağıt
          children: [
            _buildIstatistikElemani(
              icon: Icons.check_circle,
              sayi: bitirilenKitapSayisi.toString(),
              etiket: 'Bitirilen Kitap',
              renk: Colors.green,
            ),
            _buildIstatistikElemani(
              icon: Icons.menu_book,
              sayi: toplamOkunanSayfa.toString(),
              etiket: 'Toplam Sayfa',
              renk: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  // --- YENİ EKLENEN METOT: _buildIstatistikElemani ---
  // Tek bir istatistik grubunu (ikon, sayı, etiket) oluşturan metot.
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
}