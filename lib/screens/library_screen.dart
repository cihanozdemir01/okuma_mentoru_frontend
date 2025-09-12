import 'package:flutter/material.dart';
import 'package:okuma_mentoru_mobil/models/kitap.dart';
import 'package:okuma_mentoru_mobil/models/kategori.dart';
import 'package:okuma_mentoru_mobil/screens/book_detail_screen.dart';
import 'package:okuma_mentoru_mobil/services/api_service.dart';
import 'package:okuma_mentoru_mobil/widgets/kitap_karti.dart';
import 'package:okuma_mentoru_mobil/utils/snackbar_helper.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final ApiService apiService = ApiService();
  
  List<Kitap> _tumKitaplar = [];
  bool _isLoading = true;

  // Seçili filtreleri tutacak state değişkenleri
  Kategori? _selectedKategori;
  String? _selectedYazar;
  
  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    if (mounted) setState(() { _isLoading = true; });
    try {
      final kitaplar = await apiService.getFilteredBooks(
        // Artık status belirtmiyoruz, çünkü hem 'beklemede' hem 'bitti' olanları istiyoruz
        kategoriId: _selectedKategori?.id,
        yazar: _selectedYazar,
      );
      if (mounted) setState(() { _tumKitaplar = kitaplar; });
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Kitaplar yüklenirken bir hata oluştu.');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _showFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Panelin yüksekliğinin esnek olmasını sağlar
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FilterPanel(
          apiService: apiService,
          initialSelectedKategori: _selectedKategori,
          initialSelectedYazar: _selectedYazar,
          onApplyFilter: (selectedKategori, selectedYazar) {
            setState(() {
              _selectedKategori = selectedKategori;
              _selectedYazar = selectedYazar;
            });
            Navigator.pop(context);
            _loadBooks();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isFilterActive = _selectedKategori != null || _selectedYazar != null;
    final okunacaklar = _tumKitaplar.where((k) => k.status == 'beklemede').toList();
    final okunanlar = _tumKitaplar.where((k) => k.status == 'bitti').toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isFilterActive ? "Filtrelenmiş Sonuçlar" : "Kütüphanem"),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'OKUNACAKLAR'),
              Tab(text: 'OKUNANLAR'),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(isFilterActive ? Icons.filter_alt : Icons.filter_alt_off_outlined),
              onPressed: _showFilterPanel,
              tooltip: 'Filtrele',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildBookList(
                    okunacaklar, 
                    isFilterActive 
                      ? 'Bu filtreye uygun okunacak kitap bulunamadı.' 
                      : 'Henüz kütüphanene okunacak bir kitap eklememişsin.'
                  ),
                  _buildBookList(
                    okunanlar,
                    isFilterActive 
                      ? 'Bu filtreye uygun okunan kitap bulunamadı.' 
                      : 'Henüz hiç kitap bitirmemişsin. Okumaya devam et!'
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBookList(List<Kitap> kitaplar, String emptyMessage) {
    if (kitaplar.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: Colors.grey)
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadBooks,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8.0, bottom: 80.0), // Listenin altına boşluk ekle
        itemCount: kitaplar.length,
        itemBuilder: (context, index) {
          final kitap = kitaplar[index];
          return InkWell(
            onTap: () async {
              await Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => BookDetailScreen(kitap: kitap))
              );
              _loadBooks();
            },
            child: KitapKarti(kitap: kitap, finishedText: 'Okundu'),
          );
        },
      ),
    );
  }
}

// --- FİLTRELEME PANELİ WIDGET'I ---
class FilterPanel extends StatefulWidget {
  final ApiService apiService;
  final Kategori? initialSelectedKategori;
  final String? initialSelectedYazar;
  final Function(Kategori?, String?) onApplyFilter;

  const FilterPanel({
    super.key,
    required this.apiService,
    this.initialSelectedKategori,
    this.initialSelectedYazar,
    required this.onApplyFilter,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late Future<List<Kategori>> _kategorilerFuture;
  late Future<List<String>> _yazarlarFuture;
  
  Kategori? _tempSelectedKategori;
  String? _tempSelectedYazar;

  @override
  void initState() {
    super.initState();
    _kategorilerFuture = widget.apiService.getAllKategoriler();
    _yazarlarFuture = widget.apiService.getAllAuthors();
    _tempSelectedKategori = widget.initialSelectedKategori;
    _tempSelectedYazar = widget.initialSelectedYazar;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Kategoriye Göre", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            FutureBuilder<List<Kategori>>(
              future: _kategorilerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) return const Text("Kategori bulunamadı.");
                
                return Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: snapshot.data!.map((kategori) {
                    final isSelected = _tempSelectedKategori?.id == kategori.id;
                    return ChoiceChip(
                      label: Text(kategori.ad),
                      selected: isSelected,
                      onSelected: (selected) => setState(() => _tempSelectedKategori = selected ? kategori : null),
                      selectedColor: Colors.deepPurple,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                      side: BorderSide(color: isSelected ? Colors.deepPurple : Colors.grey.shade300),
                    );
                  }).toList(),
                );
              },
            ),
            const Divider(height: 32, thickness: 1),
            Text("Yazara Göre", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            FutureBuilder<List<String>>(
              future: _yazarlarFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) return const Text("Yazar bulunamadı.");
                
                return Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: snapshot.data!.map((yazar) {
                    final isSelected = _tempSelectedYazar == yazar;
                    return ChoiceChip(
                      label: Text(yazar),
                      selected: isSelected,
                      onSelected: (selected) => setState(() => _tempSelectedYazar = selected ? yazar : null),
                      selectedColor: Colors.deepPurple,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                      side: BorderSide(color: isSelected ? Colors.deepPurple : Colors.grey.shade300),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (_tempSelectedKategori != null || _tempSelectedYazar != null)
                  OutlinedButton(
                    onPressed: () {
                      widget.onApplyFilter(null, null);
                    },
                    child: const Text("Filtreyi Temizle"),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    widget.onApplyFilter(_tempSelectedKategori, _tempSelectedYazar);
                  },
                  child: const Text("Uygula"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}