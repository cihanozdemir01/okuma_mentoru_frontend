// lib/screens/book_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:okuma_mentoru_mobil/models/kitap.dart';
import 'package:okuma_mentoru_mobil/models/not.dart';
import 'package:okuma_mentoru_mobil/services/api_service.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:okuma_mentoru_mobil/utils/snackbar_helper.dart';
import 'package:okuma_mentoru_mobil/screens/edit_book_screen.dart';



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

  // Arayüzü anlık olarak güncellemek için kitabın durumunu state'te tutuyoruz.
  late String _guncelStatus;

  @override
  void initState() {
    super.initState();
    _guncelSayfa = widget.kitap.currentPage;
    _guncelStatus = widget.kitap.status; // Durumu başlangıçta ata
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    _notlarFuture = apiService.getNotlar(widget.kitap.id);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _notEklemeController.dispose();
    super.dispose();
  }

  // YENİ METOT: Düzenleme ekranını açar
  void _navigateToEditScreen() async {
    // Düzenleme ekranına git ve geri bir sonuç döndürüp döndürmediğini bekle
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditBookScreen(kitap: widget.kitap)),
    );

    // Eğer düzenleme ekranı 'true' sonucuyla döndüyse (yani bir değişiklik yapıldıysa),
    // bu detay sayfasını da yenilemek için geri dön.
    if (result == true && mounted) {
      Navigator.pop(context, true); // Bir önceki listeleme ekranına 'yenile' sinyali gönder
    }
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
                    // BAŞARI MESAJI (Önce dialog'u kapatıp sonra ana context'te gösteriyoruz)
                    Navigator.of(context).pop(); // Dialog'u kapat
                    SnackBarHelper.showSuccess(context, 'Kitap başarıyla silindi.');
                    Navigator.of(context).pop(); // Detay ekranını kapat
                  }
                } catch (e) {
                  print('Kitap silinirken hata: $e');
                  if (mounted) {
                    // HATA MESAJI
                    Navigator.of(context).pop(); // Hata olsa bile dialog'u kapat
                    SnackBarHelper.showError(context, 'Kitap silinirken bir hata oluştu.');
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
  // --- Not Ekleme ---
  // _addNot metodunun içini bununla değiştirin
Future<void> _addNot() async {
    final icerik = _notEklemeController.text;
    if (icerik.isEmpty) {
      SnackBarHelper.showError(context, 'Not alanı boş bırakılamaz.');
      return;
    }

    try {
      // HATA DÜZELTMESİ: Burada eski 'addNot' yerine, api_service.dart dosyasındaki
      // doğru ve tek metot olan 'addNotForBook'u çağırıyoruz.
      await apiService.addNotForBook(widget.kitap.id, icerik);
      
      _notEklemeController.clear();
      FocusScope.of(context).unfocus(); 
      
      // Not listesini yenile
      setState(() {
        _notlarFuture = apiService.getNotlar(widget.kitap.id);
      });
      
      SnackBarHelper.showSuccess(context, 'Not başarıyla eklendi.');
    } catch (e) {
      print('Not eklenirken hata: $e');
      if (mounted) {
        SnackBarHelper.showError(context, 'Not eklenirken bir hata oluştu. Sunucunuzun çalıştığından emin olun.');
      }
    }
  }

   Future<void> _saveProgress({bool markAsFinished = false}) async {
    // Eğer kitabı bitir butonu kullanıldıysa, güncel sayfayı total'e eşitle
    int sayfaToSave = markAsFinished ? widget.kitap.totalPages : _guncelSayfa;

    try {
      String? newStatus;
      bool isFinished = false;
      
      // Kitabın bittiğini kontrol et (ya butonla ya da slider ile)
      if (markAsFinished || (sayfaToSave >= widget.kitap.totalPages && _guncelStatus == 'okunuyor')) {
        newStatus = 'bitti';
        isFinished = true;
      }
      
      await apiService.updateKitap(widget.kitap.id, currentPage: sayfaToSave, status: newStatus);

      if (isFinished) {
        _confettiController.play();
      }

      if (mounted) {
        SnackBarHelper.showSuccess(context, 'İlerleme başarıyla kaydedildi!');
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'İlerleme kaydedilirken bir hata oluştu.');
      }
    }
  }
   Future<void> _startReading() async {
    try {
      // Kitabın durumunu 'okunuyor' olarak güncellemek için API'yi çağır
      // 'currentPage' 0 olarak kalacak, sadece status değişecek
      await apiService.updateKitap(widget.kitap.id, currentPage: _guncelSayfa, status: 'okunuyor');
      
      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Okuma serüvenin başladı!');
        // Sayfanın durumunu anında güncelle ve bir önceki sayfaya dön
        Navigator.pop(context, true); // Geri dönerken 'yenile' sinyali gönder
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Kitap güncellenirken bir hata oluştu.');
      }
    }
  }
  // --- _buildProgressTracker ---
  // İlerleme kaydetme bölümünü (Slider, butonlar) oluşturan yardımcı metot
   Widget _buildProgressTracker() {
    // YENİ: Eğer kitap 'beklemede' durumundaysa...
    if (_guncelStatus == 'beklemede') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.play_circle_fill_outlined),
          label: const Text('Okumaya Başla'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18),
          ),
          onPressed: _startReading,
        ),
      );
    }

    // Eğer kitap 'okunuyor' durumundaysa...
    return Column(
      children: [
        Text('İlerleme: $_guncelSayfa / ${widget.kitap.totalPages}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Slider(
          value: _guncelSayfa.toDouble(),
          min: 0,
          max: widget.kitap.totalPages.toDouble(),
          divisions: widget.kitap.totalPages > 0 ? widget.kitap.totalPages : null,
          label: _guncelSayfa.round().toString(),
          onChanged: (double value) {
            setState(() { _guncelSayfa = value.round(); });
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _saveProgress(),
            child: const Text('İlerlemeyi Kaydet'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton( // Yeni "Kitabı Bitir" butonu
            onPressed: () => _saveProgress(markAsFinished: true),
            child: const Text('Kitabı Bitir'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kitap.title),
        actions: [
          // YENİ DÜZENLEME BUTONU
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _navigateToEditScreen,
            tooltip: 'Kitabı Düzenle',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
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
                _buildProgressTracker(),
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
                              subtitle: Text('Eklendi: ${not.olusturmaTarihiFormatli}'),
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