// lib/models/not.dart

// YENİ: Not'un içinde gelen 'kitap' JSON objesini temsil etmek için.
class KitapIcerik {
  final int id;
  final String title;

  KitapIcerik({
    required this.id,
    required this.title,
  });

  factory KitapIcerik.fromJson(Map<String, dynamic> json) {
    return KitapIcerik(
      id: json['id'],
      title: json['title'],
    );
  }
}


class Not {
  final int id;
  // DEĞİŞİKLİK: 'kitapId' yerine artık 'kitap' nesnesini tutacağız.
  // Bu, API'den gelen iç içe JSON yapısıyla uyumlu.
  final KitapIcerik? kitap; 
  final String icerik;
  
  // YENİ ALAN: API'den gelen formatlı tarihi tutmak için.
  final String olusturmaTarihiFormatli; 

  Not({
    required this.id,
    this.kitap,
    required this.icerik,
    required this.olusturmaTarihiFormatli,
  });

  factory Not.fromJson(Map<String, dynamic> json) {
    return Not(
      id: json['id'],
      
      // DEĞİŞİKLİK: 'kitap' alanı artık bir JSON nesnesi, bu yüzden onu 
      // KitapIcerik.fromJson ile parse ediyoruz. Null gelme ihtimaline karşı kontrol ekliyoruz.
      kitap: json['kitap'] != null ? KitapIcerik.fromJson(json['kitap']) : null,
      
      icerik: json['icerik'],
      
      // YENİ ALAN: JSON'dan gelen yeni alanı okuyoruz.
      olusturmaTarihiFormatli: json['olusturma_tarihi_formatli'] ?? '', // Null gelirse boş string ata
    );
  }
}