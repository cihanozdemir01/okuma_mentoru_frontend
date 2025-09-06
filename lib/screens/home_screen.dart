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
          return const Center(child: Text('Bu listede henüz kitap yok.'));
        } else {
          // Gelen tüm kitapları, istenen statüye göre filtrele.
          final filtrelenmisKitaplar = snapshot.data!
              .where((kitap) => kitap.status == status)
              .toList();

          if (filtrelenmisKitaplar.isEmpty) {
            return const Center(child: Text('Bu listede henüz kitap yok.'));
          }

          return ListView.builder(
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
          );
        }
      },
    );
  }
}