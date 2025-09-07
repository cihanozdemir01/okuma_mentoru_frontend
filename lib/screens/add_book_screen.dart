// lib/screens/add_book_screen.dart

import 'package:flutter/material.dart';
import 'package:okuma_mentoru_mobil/services/api_service.dart';
import 'package:okuma_mentoru_mobil/utils/snackbar_helper.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  // --- YENİ EKLENEN ANAHTAR ---
  // Form'un durumunu yönetmek ve doğrulamak için bir GlobalKey oluşturuyoruz.
  final _formKey = GlobalKey<FormState>();
  // --- ANAHTARIN SONU ---

  final ApiService apiService = ApiService();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _pagesController = TextEditingController();

  // isLoading state'i ve _saveProgress metodu
  bool _isLoading = false;

  Future<void> _saveProgress() async {
    // 1. Formun geçerli olup olmadığını kontrol et.
    if (_formKey.currentState!.validate()) {
      // Eğer geçerliyse, yüklenme durumunu başlat.
      setState(() {
        _isLoading = true;
      });

      final title = _titleController.text;
      final author = _authorController.text;
      final totalPages = int.parse(_pagesController.text); // int.parse yeterli, kontrolü validatör yapıyor.

      try {
        await apiService.addKitap(title, author, totalPages);
        
        if (mounted) {
          SnackBarHelper.showSuccess(context, 'Kitap başarıyla eklendi!');
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          SnackBarHelper.showError(context, 'Kitap eklenirken bir hata oluştu.');
        }
      } finally {
        // İşlem başarılı da olsa, hata da olsa yüklenme durumunu bitir.
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _pagesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Kitap Ekle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // --- YENİ WIDGET: Form ---
        child: Form(
          key: _formKey, // Form'u anahtarımızla ilişkilendiriyoruz.
          child: ListView( // Column yerine ListView kullanarak klavye açıldığında taşmayı önlüyoruz.
            children: [
              // --- WIDGET GÜNCELLEMESİ: TextFormField ---
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Kitap Başlığı'),
                // Doğrulama kuralı
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lütfen bir kitap başlığı girin.';
                  }
                  return null; // null döndürmek, 'geçerli' demektir.
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(labelText: 'Yazar'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lütfen bir yazar adı girin.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pagesController,
                decoration: const InputDecoration(labelText: 'Toplam Sayfa Sayısı'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen sayfa sayısını girin.';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Lütfen geçerli bir sayı girin.';
                  }
                  if (int.parse(value) <= 0) {
                    return 'Sayfa sayısı 0\'dan büyük olmalı.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              // --- GÜNCELLENEN BUTON ---
              // Yüklenme durumuna göre ya butonu ya da animasyonu gösteriyoruz.
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveProgress,
                      child: const Text('Kaydet'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}