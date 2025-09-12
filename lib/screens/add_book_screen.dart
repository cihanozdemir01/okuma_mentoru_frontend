import 'package:flutter/material.dart';
import 'package:okuma_mentoru_mobil/models/kategori.dart';
import 'package:okuma_mentoru_mobil/services/api_service.dart';
import 'package:okuma_mentoru_mobil/utils/snackbar_helper.dart';
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

  // YENİ: Kullanıcının seçtiği kategorileri tutacak liste
  final List<Kategori> _selectedKategoriler = [];

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

  // GÜNCELLENDİ: Artık seçilen kategorileri de API'ye gönderiyor
  Future<void> _saveProgress() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      final title = _titleController.text;
      final author = _authorController.text;
      final totalPages = int.parse(_pagesController.text);
      
      // Seçilen kategori nesnelerinden sadece ID'lerini içeren bir liste oluştur
      final kategoriIdleri = _selectedKategoriler.map((k) => k.id).toList();

      try {
        // GÜNCELLENMİŞ ÇAĞRI: Yeni `addKitap` metodunu kategori ID'leri ile çağır
        await apiService.addKitap(title, author, totalPages, kategoriIdleri: kategoriIdleri);
        
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

  // YENİ: Kategori seçim panelini açan metot
  void _showKategoriSecimPaneli() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Panelin içeriği için ayrı bir widget kullanıyoruz
        return KategoriSecimPaneli(
          apiService: apiService,
          // Mevcut seçili kategorileri panele gönderiyoruz
          initialSelectedKategoriler: _selectedKategoriler,
          onSelectionDone: (yeniSecilenler) {
            // Panelden dönen yeni seçimleri ana sayfanın state'ine atıyoruz
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
        title: const Text('Yeni Kitap Ekle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _isLoading ? null : _scanBarcode,
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
              const SizedBox(height: 24),

              // YENİ: Kategori Seçim Bölümü
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

// YENİ WIDGET: Kategori seçim panelinin kendisi
class KategoriSecimPaneli extends StatefulWidget {
  final ApiService apiService;
  final List<Kategori> initialSelectedKategoriler;
  final Function(List<Kategori>) onSelectionDone;

  const KategoriSecimPaneli({
    super.key, required this.apiService, required this.initialSelectedKategoriler, required this.onSelectionDone,
  });

  @override
  State<KategoriSecimPaneli> createState() => _KategoriSecimPaneliState();
}

class _KategoriSecimPaneliState extends State<KategoriSecimPaneli> {
  late Future<List<Kategori>> _kategorilerFuture;
  // Geçici seçimleri tutmak için
  late List<Kategori> _tempSelectedKategoriler;

  @override
  void initState() {
    super.initState();
    _kategorilerFuture = widget.apiService.getAllKategoriler();
    // Başlangıçtaki seçimlerin bir kopyasını oluşturuyoruz
    _tempSelectedKategoriler = List.from(widget.initialSelectedKategoriler);
  }

  void _onKategoriSelected(bool selected, Kategori kategori) {
    setState(() {
      if (selected) {
        _tempSelectedKategoriler.add(kategori);
      } else {
        _tempSelectedKategoriler.removeWhere((k) => k.id == kategori.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Kategori Seç", style: Theme.of(context).textTheme.headlineSmall),
          ),
          Expanded(
            child: FutureBuilder<List<Kategori>>(
              future: _kategorilerFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final allKategoriler = snapshot.data!;
                return ListView.builder(
                  controller: controller,
                  itemCount: allKategoriler.length,
                  itemBuilder: (context, index) {
                    final kategori = allKategoriler[index];
                    final isSelected = _tempSelectedKategoriler.any((k) => k.id == kategori.id);
                    return CheckboxListTile(
                      title: Text(kategori.ad),
                      value: isSelected,
                      onChanged: (bool? selected) {
                        if (selected != null) {
                          _onKategoriSelected(selected, kategori);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // "Tamam" butonuna basıldığında seçimleri geri gönder
                widget.onSelectionDone(_tempSelectedKategoriler);
              },
              child: const Text("Tamam"),
            ),
          ),
        ],
      ),
    );
  }
}