// lib/models/kitap.dart
import 'package:okuma_mentoru_mobil/models/kategori.dart'; // YENİ IMPORT


class Kitap {
  final int id;
  final String title;
  final String author;
  final int totalPages;
  int currentPage;
  String status;

  final String? coverImageUrl;
  final List<Kategori> kategoriler;


  Kitap({
    required this.id,
    required this.title,
    required this.author,
    required this.totalPages,
    required this.currentPage,
    required this.status,
    this.coverImageUrl, 
    required this.kategoriler, // YENİ: Constructor'a ekle

  });

  factory Kitap.fromJson(Map<String, dynamic> json) {
    var kategoriList = json['kategoriler'] as List? ?? [];
    List<Kategori> parsedKategoriler = kategoriList.map((k) => Kategori.fromJson(k)).toList();
    return Kitap(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      totalPages: json['total_pages'],
      currentPage: json['current_page'],
      status: json['status'],
      coverImageUrl: json['cover_image_url'],
      kategoriler: parsedKategoriler, // YENİ: Parsed listeyi ata
    );
  }
}