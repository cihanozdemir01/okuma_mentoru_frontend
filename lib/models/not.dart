// lib/models/not.dart

class Not {
  final int id;
  final String icerik;
  final String olusturmaTarihi; // Bu değişken adını değiştirmemize gerek yok

  Not({
    required this.id,
    required this.icerik,
    required this.olusturmaTarihi,
  });

  factory Not.fromJson(Map<String, dynamic> json) {
    return Not(
      id: json['id'],
      icerik: json['icerik'],
      
      // --- TEK DEĞİŞİKLİK BURADA ---
      // JSON'dan okurken, Django'dan gelen yeni alanın adını kullanıyoruz.
      olusturmaTarihi: json['olusturma_tarihi_formatli'], 
    );
  }
}