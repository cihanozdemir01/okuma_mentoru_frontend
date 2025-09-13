import 'package:flutter/material.dart';
import 'package:okuma_mentoru_mobil/screens/chat_screen.dart'; // Birazdan oluşturacağız

class CharacterSelectionScreen extends StatelessWidget {
  const CharacterSelectionScreen({super.key});

  // Şimdilik manuel karakter listesi
  final List<Map<String, String>> karakterler = const [
    {'kitap': 'Suç ve Ceza', 'karakter': 'Raskolnikov'},
    {'kitap': 'Yabancı', 'karakter': 'Meursault'},
    {'kitap': 'Don Kişot', 'karakter': 'Don Kişot'},
    {'kitap': 'Harry Potter', 'karakter': 'Albus Dumbledore'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bir Karakter Seç"),
      ),
      body: ListView.builder(
        itemCount: karakterler.length,
        itemBuilder: (context, index) {
          final item = karakterler[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(item['karakter']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(item['kitap']!),
              trailing: const Icon(Icons.chat_bubble_outline),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      kitapAdi: item['kitap']!,
                      karakterAdi: item['karakter']!,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}