import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:okuma_mentoru_mobil/models/kitap.dart';
import 'package:okuma_mentoru_mobil/models/not.dart';
import 'package:okuma_mentoru_mobil/models/home_screen_data.dart';
import 'package:okuma_mentoru_mobil/models/kategori.dart';

// --- YARDIMCI MODELLER ---

class SummaryData {
  final DateTime period;
  final int value;

  SummaryData({required this.period, required this.value});

  factory SummaryData.fromJson(Map<String, dynamic> json) {
    return SummaryData(
      period: DateTime.parse(json['period']),
      value: json['value'] ?? 0,
    );
  }
}

class FoundBook {
  final String title;
  final String author;
  final int totalPages;
  final String? coverImageUrl;

  FoundBook({
    required this.title,
    required this.author,
    required this.totalPages,
    this.coverImageUrl,
  });

  factory FoundBook.fromJson(Map<String, dynamic> json) {
    return FoundBook(
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      totalPages: json['total_pages'] ?? 0,
      coverImageUrl: json['cover_image_url'],
    );
  }
}

class ApiService {
  final String baseUrl = "http://10.0.2.2:8000";

  // --- KİTAP İŞLEMLERİ ---

  Future<HomeScreenData> getHomeScreenData() async {
    final response = await http.get(Uri.parse('$baseUrl/api/kitaplar/'));
    if (response.statusCode == 200) {
      return HomeScreenData.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Ana ekran verileri yüklenemedi. Hata kodu: ${response.statusCode}');
    }
  }

  Future<List<Kitap>> getFilteredBooks({
    String? status,
    String? yazar,
    int? kategoriId,
  }) async {
    Uri uri = Uri.parse('$baseUrl/api/kitaplar/');
    final Map<String, String> queryParameters = {};
    if (status != null) queryParameters['status'] = status;
    if (yazar != null && yazar.isNotEmpty) queryParameters['yazar'] = yazar;
    if (kategoriId != null) queryParameters['kategori'] = kategoriId.toString();
    if (queryParameters.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParameters);
    }
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> kitaplarJson = data['kitaplar'] as List;
      return kitaplarJson.map((json) => Kitap.fromJson(json)).toList();
    } else {
      throw Exception('Filtrelenmiş kitaplar yüklenemedi.');
    }
  }

  // GÜNCELLENEN METOT: Artık opsiyonel olarak bir kategori ID listesi alabiliyor.
  Future<Kitap> addKitap(String title, String author, int totalPages, {List<int>? kategoriIdleri}) async {
    // Gönderilecek olan JSON verisini bir Map olarak hazırlıyoruz.
    final Map<String, dynamic> body = {
      'title': title,
      'author': author,
      'total_pages': totalPages,
    };

    // Eğer kategori ID'leri listesi boş değilse, onu da Map'e ekliyoruz.
    if (kategoriIdleri != null && kategoriIdleri.isNotEmpty) {
      body['kategoriler'] = kategoriIdleri;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/kitaplar/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      // Hazırladığımız Map'i JSON string'ine çeviriyoruz.
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      return Kitap.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      print('Sunucudan gelen cevap: ${response.body}');
      throw Exception('Kitap eklenemedi. Hata kodu: ${response.statusCode}');
    }
  }

  Future<void> deleteKitap(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/kitaplar/$id/'));
    if (response.statusCode != 204) {
      throw Exception('Kitap silinemedi. Hata kodu: ${response.statusCode}');
    }
  }

  Future<void> updateKitap(
    int id, {
    String? title,
    String? author,
    int? totalPages,
    int? currentPage,
    String? status,
    List<int>? kategoriIdleri,
  }) async {
    // Gönderilecek olan JSON verisini bir Map olarak hazırlayalım.
    final Map<String, dynamic> body = {};

    // Sadece null olmayan (yani güncellenmek istenen) alanları Map'e ekle
    if (title != null) body['title'] = title;
    if (author != null) body['author'] = author;
    if (totalPages != null) body['total_pages'] = totalPages;
    if (currentPage != null) body['current_page'] = currentPage;
    if (status != null) body['status'] = status;
    if (kategoriIdleri != null) body['kategoriler'] = kategoriIdleri;

    // Eğer güncellenecek hiçbir alan yoksa, isteği gönderme
    if (body.isEmpty) return;

    final response = await http.patch( // Tam güncelleme için PUT, kısmi için PATCH daha doğrudur
      Uri.parse('$baseUrl/api/kitaplar/$id/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      print('Sunucudan gelen cevap: ${response.body}');
      throw Exception('Kitap güncellenemedi. Hata kodu: ${response.statusCode}');
    }
  }

  Future<FoundBook?> findBookByIsbn(String isbn) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/find-book/?isbn=$isbn'));
      if (response.statusCode == 200) {
        return FoundBook.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- NOT İŞLEMLERİ ---

  Future<List<Not>> getNotlar(int kitapId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/kitaplar/$kitapId/notlar/'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Not.fromJson(json)).toList();
    } else {
      throw Exception('Notlar yüklenemedi. Hata kodu: ${response.statusCode}');
    }
  }

  Future<List<Not>> getAllNotes() async {
    final response = await http.get(Uri.parse('$baseUrl/api/notes/'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((json) => Not.fromJson(json)).toList();
    } else {
      throw Exception('Tüm notlar yüklenemedi. Hata kodu: ${response.statusCode}');
    }
  }

  Future<Not> addNotForBook(int kitapId, String icerik) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/kitaplar/$kitapId/notlar/'),
      headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(<String, String>{'icerik': icerik}),
    );
    if (response.statusCode == 201) {
      return Not.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Not eklenemedi. Hata kodu: ${response.statusCode}');
    }
  }

  // --- İSTATİSTİK, KATEGORİ & YAZAR İŞLEMLERİ ---
  
  // ESKİ getMonthlySummary METODU SİLİNDİ.
  
  Future<Map<String, int>> getHeatmapData() async {
    final response = await http.get(Uri.parse('$baseUrl/api/stats/heatmap/'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((key, value) => MapEntry(key, value as int));
    } else {
      throw Exception('Heatmap verisi yüklenemedi.');
    }
  }
  
  Future<List<Kategori>> getAllKategoriler() async {
    final response = await http.get(Uri.parse('$baseUrl/api/kategoriler/'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((json) => Kategori.fromJson(json)).toList();
    } else {
      throw Exception('Kategoriler yüklenemedi. Hata kodu: ${response.statusCode}');
    }
  }

  Future<List<String>> getAllAuthors() async {
    final response = await http.get(Uri.parse('$baseUrl/api/authors/'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.cast<String>().toList();
    } else {
      throw Exception('Yazarlar yüklenemedi. Hata kodu: ${response.statusCode}');
    }
  }

  // YENİ VE BİRLEŞİK METOT: Tüm grafikleri bu metot besleyecek.
  Future<List<SummaryData>> getSummary({
    String metric = 'page_count',
    String groupBy = 'month',
  }) async {
    final queryParameters = {'metric': metric, 'group_by': groupBy};
    final uri = Uri.parse('$baseUrl/api/stats/summary/').replace(queryParameters: queryParameters);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((json) => SummaryData.fromJson(json)).toList();
    } else {
      throw Exception('Özet verisi yüklenemedi. Hata: ${response.body}');
    }
  }

  // --- YAPAY ZEKA SOHBET İŞLEMLERİ ---

  Future<String> getCharacterResponse({
    required String kitapAdi,
    required String karakterAdi,
    required String kullaniciSorusu,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/character-chat/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'kitap_adi': kitapAdi,
        'karakter_adi': karakterAdi,
        'kullanici_sorusu': kullaniciSorusu,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data['cevap'] ?? "Bir cevap alınamadı.";
    } else {
      final Map<String, dynamic> errorData = json.decode(utf8.decode(response.bodyBytes));
      throw Exception('Yapay zeka ile iletişimde hata: ${errorData['error']}');
    }
  }
}