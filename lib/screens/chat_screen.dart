import 'package:flutter/material.dart';
import 'package:okuma_mentoru_mobil/services/api_service.dart';
import 'package:okuma_mentoru_mobil/utils/snackbar_helper.dart';

// Mesajları tutacak basit bir model
class ChatMessage {
  final String text;
  final bool isUser; // Mesaj kullanıcıdan mı geldi, AI'dan mı?
  ChatMessage({required this.text, required this.isUser});
}

class ChatScreen extends StatefulWidget {
  final String kitapAdi;
  final String karakterAdi;

  const ChatScreen({super.key, required this.kitapAdi, required this.karakterAdi});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // Listenin en altına kaydırmak için
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Karakterin ilk selamlama mesajı
    _messages.add(ChatMessage(
      text: "Merhaba, ben ${widget.karakterAdi}. Aklından geçenleri merak ediyorum...",
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final String soru = _textController.text.trim();
    if (soru.isEmpty) return;

    // Kullanıcının mesajını anında ekle
    setState(() {
      _messages.insert(0, ChatMessage(text: soru, isUser: true));
      _isLoading = true;
    });

    // Mesaj eklendikten sonra listenin en altına (en yeni mesaja) kaydır
    _scrollToBottom();

    _textController.clear();

    try {
      final cevap = await _apiService.getCharacterResponse(
        kitapAdi: widget.kitapAdi,
        karakterAdi: widget.karakterAdi,
        kullaniciSorusu: soru,
      );
      if (mounted) {
        setState(() {
          _messages.insert(0, ChatMessage(text: cevap, isUser: false));
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.insert(0, ChatMessage(text: "Üzgünüm, şu an sana cevap veremiyorum. Zihnim biraz karışık...", isUser: false));
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  // YENİ METOT: Sohbeti temizler
  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add(ChatMessage(
        text: "Merhaba, ben ${widget.karakterAdi}. Aklından geçenleri merak ediyorum...",
        isUser: false,
      ));
    });
    SnackBarHelper.showInfo(context, 'Sohbet geçmişi temizlendi.');
  }

  // YENİ METOT: Sohbeti temizlemeden önce onay sorar
  void _showClearConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sohbeti Temizle'),
          content: Text('${widget.karakterAdi} ile olan tüm sohbet geçmişini silmek istediğinize emin misiniz?'),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Temizle', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _clearChat();
              },
            ),
          ],
        );
      },
    );
  }

  void _scrollToBottom() {
    // Küçük bir gecikme, widget'ın listeye eklenmesine zaman tanır
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.karakterAdi} ile Sohbet"),
        // YENİ: AppBar'a silme butonu eklendi
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _showClearConfirmationDialog,
            tooltip: 'Sohbeti Temizle',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          _buildTextInputArea(),
        ],
      ),
    );
  }
  
  Widget _buildMessageBubble(ChatMessage message) {
    final theme = Theme.of(context);
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isUser ? theme.colorScheme.primaryContainer : theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text, 
          style: TextStyle(
            fontSize: 16,
            color: message.isUser ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildTextInputArea() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: "Sorunu buraya yaz...",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: _isLoading ? null : (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.send),
              onPressed: _isLoading ? null : _sendMessage,
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}