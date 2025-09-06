// lib/screens/book_detail_screen.dart

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:okuma_mentoru_mobil/models/kitap.dart';
import 'package:okuma_mentoru_mobil/models/not.dart';
import 'package:okuma_mentoru_mobil/services/api_service.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class BookDetailScreen extends StatefulWidget {
  final Kitap kitap;
  const BookDetailScreen({super.key, required this.kitap});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late ConfettiController _confettiController;
  late int _guncelSayfa;
  final ApiService apiService = ApiService();

  late Future<List<Not>> _notlarFuture;
  final _notEklemeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _guncelSayfa = widget.kitap.currentPage;
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    _notlarFuture = apiService.getNotlar(widget.kitap.id);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _notEklemeController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kitabı Sil'),
          content: const Text('Bu kitabı okuma listenizden silmek istediğinize emin misiniz?'),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                try {
                  await apiService.deleteKitap(widget.kitap.id);
                  if (mounted) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  print('Kitap silinirken hata: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }
  // --- Not Ekleme ---
  Future<void> _addNot() async {
    final icerik = _notEklemeController.text;
    if (icerik.isEmpty) return; // Boş not eklenmesin

    try {
      await apiService.addNot(widget.kitap.id, icerik);
      _notEklemeController.clear(); // Yazı alanını temizle
      // Not listesini yenile
      setState(() {
        _notlarFuture = apiService.getNotlar(widget.kitap.id);
      });
    } catch (e) {
      print('Not eklenirken hata: $e');
    }
  }

  Future<void> _saveProgress() async {
    bool isFinished = false;
    try {
      String? newStatus;
      if (_guncelSayfa >= widget.kitap.totalPages && widget.kitap.status == 'okunuyor') {
        newStatus = 'bitti';
        isFinished = true; // Kitabın bittiğini işaretle
      }

      // Önce API'ye isteği gönder
      await apiService.updateKitap(widget.kitap.id, _guncelSayfa, status: newStatus);

      // İstek başarılıysa ve kitap bittiyse konfetiyi oynat
      if (isFinished) {
        _confettiController.play();
      }

      // Konfeti animasyonu bitince veya hemen ana ekrana dön
      // Animasyonun bitmesini beklemek için küçük bir gecikme ekleyebiliriz.
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Kitap güncellenirken hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kitap.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteConfirmationDialog,
            tooltip: 'Kitabı Sil',
          ),
        ],
      ),
      // Scaffold'un body'sini Stack ile sarmalıyoruz
     body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView( // Column yerine ListView kullanarak ekran taşmasını önlüyoruz
              children: [
                // --- Kitap Bilgileri Bölümü ---
                Text('Yazar: ${widget.kitap.author}', style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic)),
                const SizedBox(height: 24),
                Text('İlerleme: $_guncelSayfa / ${widget.kitap.totalPages}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Slider(
                  value: _guncelSayfa.toDouble(),
                  min: 0,
                  max: widget.kitap.totalPages.toDouble(),
                  // Kitabın toplam sayfa sayısı 0 ise hata vermemesi için kontrol.
                  divisions: widget.kitap.totalPages > 0 ? widget.kitap.totalPages : null,
                  label: _guncelSayfa.round().toString(),
                  onChanged: (double value) {
                    // Slider hareket ettikçe anlık sayfa değerini güncelle
                    setState(() {
                      _guncelSayfa = value.round();
                    });
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saveProgress, child: const Text('İlerlemeyi Kaydet'))),
                
                const Divider(height: 40, thickness: 1), // Ayırıcı çizgi
                
                // --- Notlar Bölümü ---
                const Text('Notlarım', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                // Yeni Not Ekleme Formu
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _notEklemeController,
                        decoration: const InputDecoration(labelText: 'Yeni bir not ekle...'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _addNot,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Not Listesi
                FutureBuilder<List<Not>>(
                  future: _notlarFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text('Notlar yüklenirken bir hata oluştu: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('Henüz hiç not eklenmemiş.');
                    } else {
                      final notlar = snapshot.data!;
                      // ListView.builder'ı doğrudan bir Column/ListView içine koyamayız.
                      // Bu yüzden küçülmesini ve kendi yüksekliğini hesaplamasını sağlıyoruz.
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: notlar.length,
                        itemBuilder: (context, index) {
                          final not = notlar[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(not.icerik),
                              subtitle: Text('Eklendi: ${not.olusturmaTarihi}'),
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // Aşağı doğru
              maxBlastForce: 5,
              minBlastForce: 1,
              emissionFrequency: 0.01,
              numberOfParticles: 100, // Parçacık sayısını artıralım
              gravity: 0.1,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }
}