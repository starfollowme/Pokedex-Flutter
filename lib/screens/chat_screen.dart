import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/api_config.dart';
import '../services/gemini_service.dart';

// Data model for a single conversation
class ChatConversation {
  final List<Map<String, String>> messages;
  final DateTime timestamp;

  ChatConversation({required this.messages, required this.timestamp});

  // Helper to get a preview of the conversation
  String get preview {
    if (messages.isEmpty) return 'Percakapan Kosong';
    final userMessage = messages.firstWhere(
      (msg) => msg['role'] == 'user',
      orElse: () => {'content': 'Mulai percakapan'},
    );
    return userMessage['content']!.length > 50
        ? '${userMessage['content']!.substring(0, 50)}...'
        : userMessage['content']!;
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _messages = []; // Changed to non-final as it will be replaced
  final ScrollController _scrollController = ScrollController();
  late GeminiService _gemini;
  bool _isLoading = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _quickReplyAnimationController;

  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonScaleAnimation;
  late AnimationController _typingDotController;

  // List to store all conversations
  final List<ChatConversation> _conversationsHistory = [];

  // Function to save current conversation to history
  void _saveCurrentConversation() {
    if (_messages.isNotEmpty) {
      // Check if this exact conversation (based on messages content) already exists
      // This prevents duplicate entries if the user repeatedly opens history without new messages
      bool alreadyExists = _conversationsHistory.any((conv) {
        if (conv.messages.length != _messages.length) return false;
        for (int i = 0; i < _messages.length; i++) {
          if (conv.messages[i]['role'] != _messages[i]['role'] ||
              conv.messages[i]['content'] != _messages[i]['content']) {
            return false;
          }
        }
        return true;
      });

      if (!alreadyExists) {
        // Create a copy of the messages list
        _conversationsHistory.add(
            ChatConversation(messages: List.from(_messages), timestamp: DateTime.now()));
        // Sort history by latest
        _conversationsHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    }
  }

  // Function to load a conversation from history
  void _loadConversation(ChatConversation conversation) {
    setState(() {
      _messages = List.from(conversation.messages);
      _isLoading = false; // Ensure loading state is false when loading history
    });
    _scrollToBottom();
    _quickReplyAnimationController.reverse(); // Hide quick replies when a history is loaded
    Navigator.of(context).pop(); // Close the history screen
  }

  // Function to clear the current chat and optionally save it
  void _startNewChat() {
    _saveCurrentConversation(); // Save before clearing
    setState(() {
      _messages = []; // Clear current messages
      _isLoading = false;
    });
    _controller.clear();
    _quickReplyAnimationController.forward(); // Show quick replies for new chat
    Navigator.of(context).pop(); // Close the history screen if called from there
  }

  // NEW: Function to delete a conversation from history
  void _deleteConversation(ChatConversation conversation) {
    setState(() {
      _conversationsHistory.remove(conversation);
    });
  }

  @override
  void initState() {
    super.initState();
    final apiKey = ApiConfig.getGeminiApiKey();
    _gemini = GeminiService(apiKey: apiKey);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();

    _quickReplyAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _sendButtonScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.easeOut),
    );

    _typingDotController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _quickReplyAnimationController.dispose();
    _scrollController.dispose();
    _controller.dispose();
    _sendButtonController.dispose();
    _typingDotController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    HapticFeedback.lightImpact();

    _sendButtonController.forward().then((_) => _sendButtonController.reverse());

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();
    _quickReplyAnimationController.reverse();

    try {
      final response = await _gemini.generateContent([text]);
      setState(() {
        _messages.add({'role': 'bot', 'content': response});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'bot', 'content': 'Maaf, terjadi kesalahan. Silakan coba lagi.'});
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildQuickReplies() {
    final List<Map<String, dynamic>> quickReplies = [
      {
        'text': 'Rekomendasikan 5 Pokémon terbaik untuk melawan Gym tipe Api',
        'icon': Icons.local_fire_department,
        'color': Colors.red.shade100,
      },
      {
        'text': 'Berikan fakta unik tentang Pikachu',
        'icon': Icons.flash_on,
        'color': Colors.yellow.shade100,
      },
      {
        'text': 'Bagaimana evolusi Eevee?',
        'icon': Icons.transform,
        'color': Colors.brown.shade100,
      },
      {
        'text': 'Pokémon tipe Air yang paling kuat apa?',
        'icon': Icons.water_drop,
        'color': Colors.blue.shade100,
      },
    ];

    // Only show quick replies if messages are empty and not loading
    if (_messages.isEmpty && !_isLoading) {
      _quickReplyAnimationController.forward();
    } else {
      if (_quickReplyAnimationController.status == AnimationStatus.completed ||
          _quickReplyAnimationController.status == AnimationStatus.forward) {
        _quickReplyAnimationController.reverse();
      }
    }


    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: _quickReplyAnimationController,
        curve: Curves.easeOutCubic,
      ),
      axisAlignment: -1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Pertanyaan Populer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: quickReplies.length,
                itemBuilder: (context, index) {
                  final reply = quickReplies[index];
                  return FadeTransition(
                    opacity: _quickReplyAnimationController,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(0.0, 0.5 + (index * 0.1)),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _quickReplyAnimationController,
                        curve: Interval(
                          0.0 + (index * 0.1),
                          1.0,
                          curve: Curves.easeOutCubic,
                        ),
                      )),
                      child: Container(
                        width: 200,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _sendMessage(reply['text']),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    reply['color'],
                                    (reply['color'] as Color).withOpacity(0.7),
                                  ],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    reply['icon'],
                                    size: 28,
                                    color: Colors.grey.shade700,
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Text(
                                      reply['text'],
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(Map<String, String> msg, int index) {
    final isUser = msg['role'] == 'user';
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Row(
                mainAxisAlignment:
                    isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    Hero(
                      tag: 'bot_avatar_$index',
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade400, Colors.purple.shade400],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.smart_toy,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Colors.blue.shade500
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isUser ? 20 : 6),
                          bottomRight: Radius.circular(isUser ? 6 : 20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isUser
                                ? Colors.blue.shade500.withOpacity(0.3)
                                : Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        msg['content'] ?? '',
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black87,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  if (isUser) ...[
                    const SizedBox(width: 10),
                    Hero(
                      tag: 'user_avatar_$index',
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.shade100,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < 3; i++)
                  AnimatedBuilder(
                    animation: _typingDotController,
                    builder: (context, child) {
                      final double delay = i * 0.2;
                      final double easedValue = Curves.easeInOut.transform(
                        (_typingDotController.value + delay) % 1.0,
                      );
                      final double opacity = 0.4 + (0.6 * easedValue);
                      final double scale = 0.8 + (0.4 * easedValue);

                      return Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade500,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.purple.shade50,
              Colors.white,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
          image: const DecorationImage(
            image: AssetImage('assets/pokeball_pattern.png'),
            fit: BoxFit.cover,
            opacity: 0.05,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight + 10),
                child: AppBar(
                  elevation: 5,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade700,
                          Colors.purple.shade700,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    ),
                  ),
                  title: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Hero(
                          tag: 'pokeball_icon',
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Icon(
                              Icons.catching_pokemon,
                              color: Colors.red.shade700,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'PokéChat Bot',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Online',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    // History button
                    IconButton(
                      icon: const Icon(Icons.history, color: Colors.white),
                      onPressed: () {
                        // Save current conversation before navigating
                        _saveCurrentConversation();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => HistoryScreen(
                              conversations: _conversationsHistory,
                              onConversationTap: _loadConversation,
                              onNewChat: _startNewChat,
                              onDeleteConversation: _deleteConversation, // Pass the new delete function
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () {
                        // Add more menu options
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Colors.green.shade400, Colors.lightGreen.shade400],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.catching_pokemon,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                            const SizedBox(height: 32),
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [Colors.blue.shade600, Colors.purple.shade600],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: const Text(
                                'Halo, Trainer!',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tanyakan apa saja tentang Pokémon',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 48),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _messages.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length && _isLoading) {
                            return _buildTypingIndicator();
                          }
                          return _buildMessage(_messages[index], index);
                        },
                      ),
              ),

              _buildQuickReplies(),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, -5),
                    ),
                  ],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _controller,
                            onSubmitted: _sendMessage,
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'Tanya tentang Pokémon...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ScaleTransition(
                        scale: _sendButtonScaleAnimation,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isLoading
                                  ? [Colors.grey.shade400, Colors.grey.shade500]
                                  : [Colors.blue.shade600, Colors.purple.shade600],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _isLoading
                                    ? Colors.grey.shade400.withOpacity(0.3)
                                    : Colors.blue.shade600.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isLoading ? Icons.hourglass_empty : Icons.send,
                              color: Colors.white,
                              size: 26,
                            ),
                            onPressed: _isLoading
                                ? null
                                : () => _sendMessage(_controller.text),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// History Screen Widget
class HistoryScreen extends StatelessWidget {
  final List<ChatConversation> conversations;
  final Function(ChatConversation) onConversationTap;
  final VoidCallback onNewChat; // Callback for starting a new chat
  final Function(ChatConversation) onDeleteConversation; // NEW: Callback for deleting a conversation

  const HistoryScreen({
    Key? key,
    required this.conversations,
    required this.onConversationTap,
    required this.onNewChat,
    required this.onDeleteConversation, // NEW: Require the delete callback
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Percakapan', style: TextStyle(color: Colors.white)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade700,
                Colors.purple.shade700,
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment, color: Colors.white),
            tooltip: 'Mulai Percakapan Baru',
            onPressed: () {
              onNewChat();
              // Note: _startNewChat now handles popping the history screen itself
              // if it's called from within the HistoryScreen.
              // If you prefer to explicitly pop here, ensure _startNewChat doesn't pop.
              // For a typical "new chat" button, it's common to go back to the main chat.
            },
          ),
        ],
      ),
      body: conversations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat percakapan.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mulai percakapan baru untuk menyimpannya di sini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return Dismissible( // Enable swipe-to-delete
                  key: ValueKey(conversation.timestamp), // Unique key for Dismissible
                  direction: DismissDirection.endToStart, // Only allow swipe from right to left
                  background: Container( // Background when swiping
                    color: Colors.red.shade600,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white, size: 30),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog( // Confirmation dialog
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Hapus Percakapan?"),
                          content: const Text("Anda yakin ingin menghapus percakapan ini dari riwayat?"),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text("Batal"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text("Hapus", style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    onDeleteConversation(conversation); // Call the delete callback
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Percakapan berhasil dihapus")),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onConversationTap(conversation),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              conversation.preview,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${conversation.timestamp.toLocal().day}/${conversation.timestamp.toLocal().month}/${conversation.timestamp.toLocal().year} ${conversation.timestamp.toLocal().hour}:${conversation.timestamp.toLocal().minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}