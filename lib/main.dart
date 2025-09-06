// lib/main.dart

import 'package:flutter/material.dart';
// Yeni ekran dosyamızı projemize dahil ediyoruz.
import 'package:okuma_mentoru_mobil/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Hata ayıklama sırasında sağ üstte çıkan "DEBUG" etiketini kaldırır.
      debugShowCheckedModeBanner: false, 
      title: 'Okuma Mentoru',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Artık home parametresi olarak doğrudan HomeScreen widget'ımızı çağırıyoruz.
      home: const HomeScreen(),
    );
  }
}