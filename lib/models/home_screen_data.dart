// lib/models/home_screen_data.dart

import 'package:okuma_mentoru_mobil/models/kitap.dart';

class IstatistiklerData {
  final int bitirilenKitapSayisi;
  final int toplamOkunanSayfa;
  final int gunlukSeri;

  IstatistiklerData({
    required this.bitirilenKitapSayisi,
    required this.toplamOkunanSayfa,
    required this.gunlukSeri,
  });

  factory IstatistiklerData.fromJson(Map<String, dynamic> json) {
    return IstatistiklerData(
      bitirilenKitapSayisi: json['bitirilen_kitap_sayisi'],
      toplamOkunanSayfa: json['toplam_okunan_sayfa'],
      gunlukSeri: json['gunluk_seri'],
    );
  }
}

class HomeScreenData {
  final List<Kitap> kitaplar;
  final IstatistiklerData istatistikler;

  HomeScreenData({required this.kitaplar, required this.istatistikler});

  factory HomeScreenData.fromJson(Map<String, dynamic> json) {
    var kitaplarListesi = json['kitaplar'] as List;
    List<Kitap> kitaplar = kitaplarListesi.map((i) => Kitap.fromJson(i)).toList();

    var istatistikler = IstatistiklerData.fromJson(json['istatistikler']);

    return HomeScreenData(
      kitaplar: kitaplar,
      istatistikler: istatistikler,
    );
  }
}