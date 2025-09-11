import 'package:flutter/material.dart';
import 'package:okuma_mentoru_mobil/models/not.dart';
import 'package:okuma_mentoru_mobil/services/api_service.dart';

class NotesHubScreen extends StatefulWidget {
  const NotesHubScreen({super.key});

  @override
  State<NotesHubScreen> createState() => _NotesHubScreenState();
}

class _NotesHubScreenState extends State<NotesHubScreen> {
  final ApiService apiService = ApiService();
  late Future<List<Not>> allNotesFuture;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    setState(() {
      allNotesFuture = apiService.getAllNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tüm Notlarım"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadNotes();
        },
        child: FutureBuilder<List<Not>>(
          future: allNotesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final notlar = snapshot.data!;
              return ListView.builder(
                itemCount: notlar.length,
                itemBuilder: (context, index) {
                  final not = notlar[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 3,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      // Notun içeriği
                      title: Text(
                        not.icerik,
                        style: const TextStyle(fontSize: 16),
                      ),
                      // Hangi kitaba ait olduğu ve tarihi
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          // not.kitap.title null kontrolü önemli olabilir
                          "${not.kitap?.title ?? 'Bilinmeyen Kitap'}\n${not.olusturmaTarihiFormatli}",
                          style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),
                  );
                },
              );
            } else {
              return const Center(
                child: Text(
                  'Henüz hiç not almamışsın.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}