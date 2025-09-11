import 'package:flutter/material.dart';
import 'package:okuma_mentoru_mobil/models/kitap.dart';
import 'package:okuma_mentoru_mobil/screens/book_detail_screen.dart';
import 'package:okuma_mentoru_mobil/services/api_service.dart';
import 'package:okuma_mentoru_mobil/widgets/kitap_karti.dart';

class FinishedBooksScreen extends StatefulWidget {
  const FinishedBooksScreen({super.key});

  @override
  State<FinishedBooksScreen> createState() => _FinishedBooksScreenState();
}

class _FinishedBooksScreenState extends State<FinishedBooksScreen> {
  final ApiService apiService = ApiService();
  late Future<List<Kitap>> finishedBooksFuture;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  void _loadBooks() {
    setState(() {
      // Sadece 'bitti' durumundaki kitapları filtreliyoruz
      finishedBooksFuture = apiService.getHomeScreenData().then(
        (data) => data.kitaplar.where((kitap) => kitap.status == 'bitti').toList()
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Zihin Kütüphanem"), // Başlık değişti
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadBooks();
        },
        child: FutureBuilder<List<Kitap>>(
          future: finishedBooksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final kitaplar = snapshot.data!;
              return ListView.builder(
                itemCount: kitaplar.length,
                itemBuilder: (BuildContext context, int index) {
                  final kitap = kitaplar[index];
                  return InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookDetailScreen(kitap: kitap),
                        ),
                      );
                      _loadBooks();
                    },
                    child: KitapKarti(kitap: kitap),
                  );
                },
              );
            } else {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Henüz bitirdiğin bir kitap yok. Okumaya devam et!', // Metin değişti
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}