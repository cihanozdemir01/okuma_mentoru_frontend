// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:okuma_mentoru_mobil/models/home_screen_data.dart';
import 'package:okuma_mentoru_mobil/screens/add_book_screen.dart';
import 'package:okuma_mentoru_mobil/services/api_service.dart';
import 'package:okuma_mentoru_mobil/screens/currently_reading_screen.dart';
import 'package:okuma_mentoru_mobil/screens/library_screen.dart'; // Bu import'u ekle
import 'package:okuma_mentoru_mobil/screens/notes_hub_screen.dart';
import 'package:okuma_mentoru_mobil/screens/stats_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService apiService = ApiService();
  late Future<HomeScreenData> homeScreenDataFuture;

  int _yillikHedef = 0;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      homeScreenDataFuture = apiService.getHomeScreenData();
      _loadHedef();
    });
  }

  Future<void> _loadHedef() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _yillikHedef = prefs.getInt('yillikHedef') ?? 0;
      });
    }
  }

  Future<void> _saveHedef(int hedef) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('yillikHedef', hedef);
    if (mounted) {
      setState(() {
        _yillikHedef = hedef;
      });
    }
  }
  
  // HATA DÜZELTMESİ: EKSİK OLAN FONKSİYON BURAYA EKLENDİ
  // Bu fonksiyon, yeni bir sayfaya gider ve o sayfadan geri dönüldüğünde
  // ana ekran verilerini otomatik olarak yeniler.
  void _navigateToScreen(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Okuma Mentoru'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<HomeScreenData>(
        future: homeScreenDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final istatistikler = snapshot.data!.istatistikler;
            return Column(
              children: [
                _buildHedefKontrolMerkezi(istatistikler.bitirilenKitapSayisi),
                Expanded(
                  child: Center(
                    child: _buildNavigasyonKartlariIzgarasi(),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: Text("Veri bulunamadı."));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        // Yönlendirme artık bu fonksiyonu kullanıyor
        onPressed: () => _navigateToScreen(const AddBookScreen()),
        tooltip: 'Yeni Kitap Ekle',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHedefKontrolMerkezi(int bitirilenKitapSayisi) {
    // Bu widget'ta değişiklik yok...
    double ilerleme = _yillikHedef > 0 ? bitirilenKitapSayisi / _yillikHedef : 0.0;
    if (ilerleme > 1.0) ilerleme = 1.0;

    return GestureDetector(
      onTap: () => _showHedefBelirlemeDialog(),
      child: Card(
        margin: const EdgeInsets.all(16.0),
        elevation: 8.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0),
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purple.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(
                _yillikHedef > 0 ? "Yıllık Hedefin" : "Yıllık Hedef Belirle",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 15),
              Center(
                child: Text(
                  "$bitirilenKitapSayisi / $_yillikHedef Kitap",
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              if (_yillikHedef > 0)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: ilerleme,
                    minHeight: 12,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  ),
                ),
              const SizedBox(height: 15),
              Center(
                child: Text(
                  _yillikHedef > 0
                      ? "Harika gidiyorsun! Yeni bir maceraya başlamanın tam zamanı."
                      : "Başlamak için karta dokun ve bu yıl kaç kitap okuyacağını belirle!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigasyonKartlariIzgarasi() {
    // Bu widget'ta değişiklik yok...
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      child: GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 0.95, 
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        physics: const NeverScrollableScrollPhysics(), 
        shrinkWrap: true,
        children: [
            _buildNavigationCard(icon: Icons.menu_book, title: "Okuduklarım"),
            _buildNavigationCard(icon: Icons.library_books, title: "Kütüphanem"),
            _buildNavigationCard(icon: Icons.chat, title: "Sohbet"),
            _buildNavigationCard(icon: Icons.explore, title: "Keşfet"),
            _buildNavigationCard(icon: Icons.edit_note, title: "Notlarım"),
            _buildNavigationCard(icon: Icons.bar_chart, title: "Haritam"),
        ],
      ),
    );
  }

  Widget _buildNavigationCard({required IconData icon, required String title}) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: InkWell(
        onTap: () {
          // Yönlendirmeler artık _navigateToScreen fonksiyonunu kullanıyor
          if (title == "Okuduklarım") {
            _navigateToScreen(const CurrentlyReadingScreen());
          } 
          else if (title == "Kütüphanem") {
            _navigateToScreen(const LibraryScreen());
          } 
          else if (title == "Notlarım") {
            _navigateToScreen(const NotesHubScreen());
          } 
          else if (title == "Haritam") {
          _navigateToScreen(const StatsScreen());
          } 
          else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title tıklandı! Bu sayfa yakında gelecek.')),
            );
          }
        },
        borderRadius: BorderRadius.circular(15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.deepPurple),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showHedefBelirlemeDialog() async {
    // Bu widget'ta değişiklik yok...
    final TextEditingController controller = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Yıllık Hedefini Belirle'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Örn: 50"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Kaydet'),
              onPressed: () {
                final int? yeniHedef = int.tryParse(controller.text);
                if (yeniHedef != null && yeniHedef > 0) {
                  _saveHedef(yeniHedef);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}