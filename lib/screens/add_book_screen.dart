import 'package:flutter/material.dart';
import 'package:okuma_mentoru_mobil/services/api_service.dart';
import 'package:okuma_mentoru_mobil/utils/snackbar_helper.dart';

// YENİ: Barkod tarayıcı sayfasını import ediyoruz
import 'package:okuma_mentoru_mobil/screens/barcode_scanner_screen.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final ApiService apiService = ApiService();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _pagesController = TextEditingController();

  bool _isLoading = false;

  // YENİ: Barkod tarama işlemini yöneten fonksiyon
  Future<void> _scanBarcode() async {
    // Tarayıcı ekranına git ve bir sonuç bekle
    final String? barcode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    // Eğer bir barkod (ISBN) döndüyse...
    if (barcode != null && mounted) {
      setState(() { _isLoading = true; }); // Yükleniyor animasyonunu başlat

      try {
        // API'den kitap bilgilerini ara
        final FoundBook? foundBook = await apiService.findBookByIsbn(barcode);
        
        if (foundBook != null) {
          // Kitap bulunduysa, form alanlarını doldur
          _titleController.text = foundBook.title;
          _authorController.text = foundBook.author;
          _pagesController.text = foundBook.totalPages.toString();
          SnackBarHelper.showSuccess(context, 'Kitap bilgileri bulundu!');
        } else {
          // Kitap bulunamadıysa kullanıcıyı bilgilendir
          SnackBarHelper.showError(context, 'Bu ISBN ile bir kitap bulunamadı.');
        }
      } catch (e) {
        SnackBarHelper.showError(context, 'Kitap aranırken bir hata oluştu.');
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; }); // Yükleniyor animasyonunu bitir
        }
      }
    }
  }

  Future<void> _saveProgress() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      final title = _titleController.text;
      final author = _authorController.text;
      final totalPages = int.parse(_pagesController.text);

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
        if (mounted) {
          setState(() { _isLoading = false; });
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
        // YENİ: AppBar'a barkod tarama butonu ekliyoruz
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _isLoading ? null : _scanBarcode, // Yükleniyorsa butonu pasif yap
            tooltip: 'Barkod Tara',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Kitap Başlığı'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lütfen bir kitap başlığı girin.';
                  }
                  return null;
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