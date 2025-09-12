import 'package:flutter/material.dart';
import 'package:okuma_mentoru_mobil/models/kitap.dart';
import 'package:okuma_mentoru_mobil/models/kategori.dart';
import 'package:okuma_mentoru_mobil/services/api_service.dart';
import 'package:okuma_mentoru_mobil/utils/snackbar_helper.dart';
// add_book_screen.dart içindeki KategoriSecimPaneli'ni yeniden kullanıyoruz
import 'package:okuma_mentoru_mobil/screens/add_book_screen.dart'; 

class EditBookScreen extends StatefulWidget {
  final Kitap kitap;
  const EditBookScreen({super.key, required this.kitap});

  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final ApiService apiService = ApiService();
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _pagesController;

  bool _isLoading = false;

  // Kitabın mevcut kategorilerini tutacak liste
  final List<Kategori> _selectedKategoriler = [];

  @override
  void initState() {
    super.initState();
    // Controller'ları kitabın mevcut bilgileriyle başlat
    _titleController = TextEditingController(text: widget.kitap.title);
    _authorController = TextEditingController(text: widget.kitap.author);
    _pagesController = TextEditingController(text: widget.kitap.totalPages.toString());
    // Başlangıçtaki kategorileri listeye ekle
    _selectedKategoriler.addAll(widget.kitap.kategoriler);
  }

  Future<void> _updateBook() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      final title = _titleController.text;
      final author = _authorController.text;
      final totalPages = int.parse(_pagesController.text);
      final kategoriIdleri = _selectedKategoriler.map((k) => k.id).toList();

      try {
        await apiService.updateKitap(
          widget.kitap.id,
          title: title,
          author: author,
          totalPages: totalPages,
          kategoriIdleri: kategoriIdleri,
          // Diğer alanları (currentPage, status) değiştirmediğimiz için göndermiyoruz
        );
        
        if (mounted) {
          SnackBarHelper.showSuccess(context, 'Kitap başarıyla güncellendi!');
          // Geri dönerken 'true' değeri göndererek bir önceki sayfanın
          // yenilenmesi gerektiğini bildiriyoruz.
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          SnackBarHelper.showError(context, 'Kitap güncellenirken bir hata oluştu.');
        }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }
  
  void _showKategoriSecimPaneli() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // add_book_screen.dart'ta oluşturduğumuz paneli burada yeniden kullanıyoruz
        return KategoriSecimPaneli(
          apiService: apiService,
          initialSelectedKategoriler: _selectedKategoriler,
          onSelectionDone: (yeniSecilenler) {
            setState(() {
              _selectedKategoriler.clear();
              _selectedKategoriler.addAll(yeniSecilenler);
            });
            Navigator.pop(context);
          },
        );
      },
    );
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
        title: const Text('Kitabı Düzenle'),
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
                  // ... (validator kuralları add_book_screen ile aynı)
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text("Kategoriler", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showKategoriSecimPaneli,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.category_outlined, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _selectedKategoriler.isEmpty
                            ? const Text("Kategori seçmek için dokunun", style: TextStyle(color: Colors.grey))
                            : Wrap(
                                spacing: 8.0,
                                runSpacing: 4.0,
                                children: _selectedKategoriler.map((k) => Chip(label: Text(k.ad))).toList(),
                              ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _updateBook, // Artık _updateBook metodunu çağırıyor
                      child: const Text('Değişiklikleri Kaydet'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}