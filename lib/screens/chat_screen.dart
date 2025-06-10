// lib/screens/chat_screen.dart

import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../services/gemini_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  late GeminiService _gemini;

  @override
  void initState() {
    super.initState();
    final apiKey = ApiConfig.getGeminiApiKey();
    _gemini = GeminiService(apiKey: apiKey);
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'content': text});
    });
    _controller.clear();

    final response = await _gemini.generateContent([text]);
    setState(() {
      _messages.add({'role': 'bot', 'content': response});
    });
  }

  Widget _buildQuickReplies() {
    final List<String> quickReplies = [
      'Rekomendasikan 5 Pokémon terbaik untuk melawan Gym tipe Api',
      'Berikan fakta unik tentang Pikachu',
      'Bagaimana evolusi Eevee?',
      'Pokémon tipe Air yang paling kuat apa?',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: quickReplies.map((reply) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade100,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () => _sendMessage(reply),
          child: Text(reply, style: const TextStyle(fontSize: 14)),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PokéChat Bot'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.blue.shade100
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(msg['content'] ?? ''),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // 🔥 Bagian rekomendasi quick reply kayak Lazada
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildQuickReplies(),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: _sendMessage,
                    decoration: const InputDecoration(
                      hintText: 'Tanya tentang Pokémon...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
