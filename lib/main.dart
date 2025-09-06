// lib/main.dart

import 'package:flutter/material.dart';
import 'package:okuma_mentoru_mobil/screens/home_screen.dart';
import 'package:intl/date_symbol_data_local.dart'; // Doğru import

// main fonksiyonunu async olarak işaretliyoruz.
Future<void> main() async {
  // Bu satır, Flutter binding'lerinin runApp'ten önce
  // hazır olmasını garantiler. 'await' kullanmak için gereklidir.
  WidgetsFlutterBinding.ensureInitialized();
  
  // 'tr_TR' (Türkçe) için tarih formatlama verilerinin
  // yüklenmesini bekle. Bu işlem bitmeden bir sonraki satıra geçilmez.
  await initializeDateFormatting('tr_TR', null);
  
  // Tüm hazırlıklar bittikten sonra uygulamayı çalıştır.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Okuma Mentoru',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}