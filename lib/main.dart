import 'package:flutter/material.dart';
import 'package:okuma_mentoru_mobil/screens/home_screen.dart';
import 'package:intl/date_symbol_data_local.dart';


// DEĞİŞİKLİK 1: Fonksiyon "async" olarak işaretlendi.
Future<void> main() async {
  // DEĞİŞİKLİK 2: Bu satır, paketlerin uygulama başlamadan önce hazır olmasını sağlar.
  WidgetsFlutterBinding.ensureInitialized(); 
   // YENİ SATIR: Türkçe dil verilerini yüklemek için bu fonksiyonu çağırıyoruz.
  // Bu, uygulamanın herhangi bir yerinde 'tr_TR' formatını kullanabilmemizi sağlar.
  await initializeDateFormatting('tr_TR', null);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Okuma Mentoru',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}