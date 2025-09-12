import 'package:flutter/material.dart';
import 'package:okuma_mentoru_mobil/models/kitap.dart';
import 'package:cached_network_image/cached_network_image.dart';

class KitapKarti extends StatelessWidget {
  final Kitap kitap;
  final String finishedText;

  const KitapKarti({
    super.key,
    required this.kitap,
    this.finishedText = 'Tamamlandı',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            _buildBookCover(),
            const SizedBox(width: 16),
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
                  // GÜNCELLENMİŞ MANTIK: Artık 3 durumu da kontrol ediyoruz.
                  _buildStatusIndicator(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // YENİ YARDIMCI WIDGET: Kitabın durumuna göre doğru göstergeyi oluşturur.
  Widget _buildStatusIndicator() {
    if (kitap.status == 'okunuyor') {
      // Durum 'okunuyor' ise ilerleme çubuğunu göster.
      double progress = kitap.totalPages > 0 ? kitap.currentPage / kitap.totalPages : 0.0;
      if (progress > 1.0) progress = 1.0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
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
          Text(
            "${kitap.currentPage} / ${kitap.totalPages} Sayfa",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      );
    } else if (kitap.status == 'bitti') {
      // Durum 'bitti' ise "Okundu" ikonunu göster.
      return Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
          const SizedBox(width: 4),
          Text(finishedText, style: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.bold)),
        ],
      );
    } else {
      // Durum 'beklemede' veya başka bir şey ise hiçbir şey gösterme (veya "Okunacak" etiketi ekleyebiliriz)
      // Şimdilik boş bırakmak en temizi.
      return const SizedBox(height: 8); // Diğerleriyle hizayı korumak için boş bir kutu
    }
  }


  Widget _buildBookCover() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: SizedBox(
        width: 70,
        height: 100,
        child: (kitap.coverImageUrl != null && kitap.coverImageUrl!.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: kitap.coverImageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.book, color: Colors.grey)),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.error_outline, color: Colors.grey)),
                ),
              )
            : Container(
                color: Colors.grey.shade300,
                child: Center(
                  child: Icon(Icons.book_outlined, color: Colors.grey.shade600, size: 40),
                ),
              ),
      ),
    );
  }
}