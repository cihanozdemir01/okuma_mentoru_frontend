// lib/utils/snackbar_helper.dart

import 'package:flutter/material.dart';

class SnackBarHelper {
  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      Colors.green.shade700, // Daha tok bir yeşil
      Icons.check_circle,     // Başarı ikonu
    );
  }

  static void showError(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      Colors.red.shade800, // Daha tok bir kırmızı
      Icons.error,           // Hata ikonu
    );
  }
  
  // YENİ METOT: Bilgilendirme mesajları için bunu ekle
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        // Rengi istediğin gibi ayarlayabilirsin, genellikle mavi veya gri tonları kullanılır
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  // Metodun imzası artık bir ikon da alıyor.
  static void _showSnackBar(BuildContext context, String message, Color color, IconData icon) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // Ana içerik artık bir Row (yatay sıra)
        content: Row(
          children: [
            // İkonu ekliyoruz
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12), // İkon ile metin arasına boşluk
            // Metnin satır atlaması durumunda genişleyebilmesi için Expanded kullanıyoruz.
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        
        // --- YENİ EKLENEN ÖZELLİKLER ---
        // Davranışını 'floating' yaparak kenarlardan boşluklu ve yuvarlak olmasını sağlıyoruz.
        behavior: SnackBarBehavior.floating,
        
        // Kenar yuvarlaklığı
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        
        // Ekranın altından ne kadar yukarıda duracağı
        margin: const EdgeInsets.all(12.0),
        // --- YENİ ÖZELLİKLERİN SONU ---
      ),
    );
  }
}