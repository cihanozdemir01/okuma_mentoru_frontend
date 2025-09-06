// lib/models/kitap.dart

class Kitap {
  final int id;
  final String title;
  final String author;
  final int totalPages;
  final int currentPage;
  final String status;

  Kitap({
    required this.id,
    required this.title,
    required this.author,
    required this.totalPages,
    required this.currentPage,
    required this.status,
  });

  factory Kitap.fromJson(Map<String, dynamic> json) {
    return Kitap(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      totalPages: json['total_pages'],
      currentPage: json['current_page'],
      status: json['status'],
    );
  }
}