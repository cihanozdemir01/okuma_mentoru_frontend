// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:okuma_mentoru_mobil/models/kitap.dart';
import 'package:okuma_mentoru_mobil/models/not.dart';

class ApiService {
  // Android emülatöründen bilgisayarın localhost'una erişmek için '10.0.2.2' kullanılır.
  final String baseUrl = "http://10.0.2.2:8000/api";

  // Kitap listesini getiren metot
  Future<List<Kitap>> getKitaplar() async {
    // DOĞRU URL: 'baseUrl'in sonuna '/kitaplar/' ekliyoruz
    final response = await http.get(Uri.parse('$baseUrl/kitaplar/'));

    // Django API'miz, giriş yapmamış kullanıcılara izin vermediği için
    // şimdilik bu kısımları eklemiyoruz. Sadece başarılı durumu kontrol edelim.
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Kitap.fromJson(json)).toList();
    } else {
      // Hata durumunu daha anlaşılır hale getirelim.
      print('Sunucudan gelen cevap: ${response.body}');
      throw Exception('Kitaplar yüklenemedi. Hata kodu: ${response.statusCode}');
    }
  }

  Future<Kitap> addKitap(String title, String author, int totalPages) async {
    final response = await http.post(
      Uri.parse('$baseUrl/kitaplar/'),
      // Göndereceğimiz verinin JSON formatında olduğunu belirtiyoruz.
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      // Dart Map'ini JSON string'ine çeviriyoruz.
      body: jsonEncode(<String, dynamic>{
        'title': title,
        'author': author,
        'total_pages': totalPages,
        // Diğer alanlar Django tarafında varsayılan değerlere sahip olduğu için
        // onları göndermemize gerek yok (current_page=0, status='okunuyor').
      }),
    );

    // Eğer sunucu 201 Created (Başarıyla Oluşturuldu) cevabı dönerse...
    if (response.statusCode == 201) {
      // Sunucudan dönen ve yeni oluşturulan kitabın verisini
      // bir Kitap nesnesine çevirip geri döndür.
      return Kitap.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      // Hata durumunda, sunucudan gelen cevabı da yazdır.
      print('Sunucudan gelen cevap: ${response.body}');
      throw Exception('Kitap eklenemedi. Hata kodu: ${response.statusCode}');
    }
  }

  // --- YENİ METOT: Kitap Silme (DELETE) ---
  Future<void> deleteKitap(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/kitaplar/$id/'),
    );

    // 204 No Content, başarılı silme işleminde sunucunun cevap vermesidir.
    if (response.statusCode != 204) {
      print('Sunucudan gelen cevap: ${response.body}');
      throw Exception('Kitap silinemedi. Hata kodu: ${response.statusCode}');
    }
   }

  // --- YENİ METOT: Kitap Güncelleme (PUT/PATCH) ---
  Future<void> updateKitap(int id, int currentPage, {String? status}) async {
    // Gönderilecek olan JSON verisini bir Map olarak hazırlayalım.
    final Map<String, dynamic> data = {
      'current_page': currentPage,
    };

    // Eğer 'status' parametresi null değilse (yani gönderildiyse),
    // onu da data Map'ine ekle.
    if (status != null) {
      data['status'] = status;
    }

    final response = await http.patch(
      // Django REST Framework'te tekil nesneler için URL /api/kitaplar/<id>/ şeklindedir.
      Uri.parse('$baseUrl/kitaplar/$id/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      // Hazırladığımız Map'i JSON'a çevirip body olarak gönder.
      body: jsonEncode(data),
    );

    // 200 OK başarılı demektir.
    if (response.statusCode != 200) {
      print('Sunucudan gelen cevap: ${response.body}');
      throw Exception('Kitap güncellenemedi. Hata kodu: ${response.statusCode}');
    }
  }
  // --- YENİ METOT: Bir Kitaba Ait Notları Getirme ---
  Future<List<Not>> getNotlar(int kitapId) async {
    final response = await http.get(Uri.parse('$baseUrl/kitaplar/$kitapId/notlar/'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Not.fromJson(json)).toList();
    } else {
      throw Exception('Notlar yüklenemedi. Hata kodu: ${response.statusCode}');
    }
  }

  // --- YENİ METOT: Bir Kitaba Yeni Not Ekleme ---
  Future<Not> addNot(int kitapId, String icerik) async {
    final response = await http.post(
      Uri.parse('$baseUrl/kitaplar/$kitapId/notlar/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
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
}
