// lib/widgets/kitap_karti.dart

import 'package:flutter/material.dart';
import 'package:okuma_mentoru_mobil/models/kitap.dart';
import 'package:cached_network_image/cached_network_image.dart'; // YENİ IMPORT

class KitapKarti extends StatelessWidget {
  final Kitap kitap;
  const KitapKarti({super.key, required this.kitap});

  @override
  Widget build(BuildContext context) {
    double progress = kitap.totalPages > 0 ? kitap.currentPage / kitap.totalPages : 0.0;
    if (progress > 1.0) progress = 1.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // --- SOL TARAF: KİTAP KAPAĞI ---
            _buildBookCover(),

            const SizedBox(width: 16),

            // --- SAĞ TARAF: KİTAP BİLGİLERİ ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kitap.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kitap.author,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  if (kitap.status == 'okunuyor') ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "${kitap.currentPage} / ${kitap.totalPages} Sayfa",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),
                  ] else ...[
                    // Kitap bittiyse, yeşil bir "Tamamlandı" ikonu göster
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                        const SizedBox(width: 4),
                        Text("Tamamlandı", style: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.bold)),
                      ],
                    )
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Kapak görselini oluşturan yardımcı widget
  Widget _buildBookCover() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: SizedBox(
        width: 70,
        height: 100,
        // Eğer URL varsa CachedNetworkImage ile göster, yoksa yer tutucu göster
        child: (kitap.coverImageUrl != null && kitap.coverImageUrl!.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: kitap.coverImageUrl!,
                fit: BoxFit.cover,
                // Yüklenirken gösterilecek olan
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.book, color: Colors.grey)),
                ),
                // Hata olursa gösterilecek olan
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.error_outline, color: Colors.grey)),
                ),
              )
            : Container( // URL yoksa gösterilecek yer tutucu
                color: Colors.grey.shade300,
                child: Center(
                  child: Icon(Icons.book_outlined, color: Colors.grey.shade600, size: 40),
                ),
              ),
      ),
    );
  }
}