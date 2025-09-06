// lib/screens/add_book_screen.dart

import 'package:flutter/material.dart';
import 'package:okuma_mentoru_mobil/services/api_service.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  // ApiService nesnesini oluştur
  final ApiService apiService = ApiService();

  // Form alanlarındaki metni okumak için Controller'lar
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _pagesController = TextEditingController();

  // Widget ağaçtan kaldırıldığında controller'ları temizle
  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _pagesController.dispose();
    super.dispose();
  }

  // "Kaydet" butonuna tıklandığında çalışacak olan asenkron metot
  Future<void> _submitData() async {
    // Form alanlarından verileri al
    final title = _titleController.text;
    final author = _authorController.text;
    // Sayfa sayısını String'den int'e çevir
    final totalPages = int.tryParse(_pagesController.text) ?? 0;

    // Alanların boş olup olmadığını kontrol et
    if (title.isNotEmpty && author.isNotEmpty && totalPages > 0) {
      try {
        // API'ye yeni kitabı ekleme isteği gönder
        await apiService.addKitap(title, author, totalPages);
        
        // İstek başarılı olursa, bir önceki ekrana geri dön
        // `mounted` kontrolü, widget hala ekrandaysa işlem yapılmasını garantiler.
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        // Hata oluşursa, konsola hatayı yazdır
        print('Kitap eklenirken hata oluştu: $e');
        // TODO: Kullanıcıya bir hata mesajı göstermek daha iyi olur (örn: SnackBar).
      }
    } else {
      // Alanlar boşsa kullanıcıyı uyar
      print('Lütfen tüm alanları doldurun.');
      // TODO: Kullanıcıya bir uyarı mesajı göstermek daha iyi olur.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Kitap Ekle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Kitap Başlığı'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(labelText: 'Yazar'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pagesController,
              decoration: const InputDecoration(labelText: 'Toplam Sayfa Sayısı'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            // Kaydet Butonu
            ElevatedButton(
              // Butona basıldığında yukarıda tanımladığımız _submitData metodunu çağır.
              onPressed: _submitData,
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}