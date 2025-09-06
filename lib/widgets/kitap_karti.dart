// lib/widgets/kitap_karti.dart

import 'package:flutter/material.dart';
import 'package:okuma_mentoru_mobil/models/kitap.dart';

// Artık bu widget'ın tek görevi bir kitap kartını ekrana çizmek.
// Tıklama veya navigasyonla ilgilenmiyor.
class KitapKarti extends StatelessWidget {
  final Kitap kitap;
  
  const KitapKarti({
    super.key,
    required this.kitap,
  });

  @override
  Widget build(BuildContext context) {
    final double ilerlemeYuzdesi = (kitap.totalPages > 0)
        ? kitap.currentPage / kitap.totalPages
        : 0.0;

    // InkWell'i buradan kaldırdık.
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... (içerik tamamen aynı kalıyor) ...
            Text(
              kitap.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              kitap.author,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: ilerlemeYuzdesi,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${kitap.currentPage} / ${kitap.totalPages} sayfa',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}