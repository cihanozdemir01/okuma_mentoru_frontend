// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:okuma_mentoru_mobil/models/kitap.dart';
import 'package:okuma_mentoru_mobil/models/not.dart';
import 'package:okuma_mentoru_mobil/models/home_screen_data.dart';

// YENİ MODEL: Aylık özet verisini tutmak için.
// Bu sınıfı ya burada ya da kendi model dosyasında tanımlayabilirsin.
class MonthlySummary {
  final String month;
  final int count;

  MonthlySummary({required this.month, required this.count});

  factory MonthlySummary.fromJson(Map<String, dynamic> json) {
    return MonthlySummary(
      month: json['month'] as String,
      count: json['count'] as int,
    );
  }
}


class ApiService {
  // Geliştirme için lokal sunucuyu kullanıyoruz.
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

  Future<Kitap> addKitap(String title, String author, int totalPages) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/kitaplar/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'title': title,
        'author': author,
        'total_pages': totalPages,
      }),
    );
    if (response.statusCode == 201) {
      return Kitap.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      print('Sunucudan gelen cevap: ${response.body}');
      throw Exception('Kitap eklenemedi. Hata kodu: ${response.statusCode}');
    }
  }

  Future<void> deleteKitap(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/kitaplar/$id/'),
    );
    if (response.statusCode != 204) {
      print('Sunucudan gelen cevap: ${response.body}');
      throw Exception('Kitap silinemedi. Hata kodu: ${response.statusCode}');
    }
  }

  Future<void> updateKitap(int id, int currentPage, {String? status}) async {
    final Map<String, dynamic> data = {'current_page': currentPage};
    if (status != null) {
      data['status'] = status;
    }
    final response = await http.patch(
      Uri.parse('$baseUrl/api/kitaplar/$id/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      print('Sunucudan gelen cevap: ${response.body}');
      throw Exception('Kitap güncellenemedi. Hata kodu: ${response.statusCode}');
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
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'icerik': icerik,
      }),
    );
    if (response.statusCode == 201) {
      return Not.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      print('Sunucudan gelen cevap: ${response.body}');
      throw Exception('Not eklenemedi. Hata kodu: ${response.statusCode}');
    }
  }

  // --- İSTATİSTİK İŞLEMLERİ ---
  
  // YENİ METOT: Aylık özet verisini çekmek için
  Future<List<MonthlySummary>> getMonthlySummary() async {
    final response = await http.get(Uri.parse('$baseUrl/api/stats/monthly-summary/'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      // Gelen her bir JSON nesnesini MonthlySummary modeline çevir
      return data.map((json) => MonthlySummary.fromJson(json)).toList();
    } else {
      throw Exception('Aylık özet yüklenemedi. Hata kodu: ${response.statusCode}');
    }
  }
  // YENİ METOT: Heatmap verisini çekmek için
  Future<Map<String, int>> getHeatmapData() async {
    final response = await http.get(Uri.parse('$baseUrl/api/stats/heatmap/'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      // Gelen verinin value'larını int'e çevir
      return data.map((key, value) => MapEntry(key, value as int));
    } else {
      throw Exception('Heatmap verisi yüklenemedi.');
    }
  }
}