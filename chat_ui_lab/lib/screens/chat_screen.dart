import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../widgets/message_bubble.dart';
import '../widgets/input_bar.dart';
import '../service/gemini_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  Future<void> _handleSend(String text) async {
    if (text.trim().isEmpty) return;

    _addMessage(text, isUserMessage: true);

    setState(() {
      _isLoading = true;
    });

    try {

      final aiResponse = await GeminiService.sendMessage(text);

      _addMessage(aiResponse, isUserMessage: false);
    } catch (e) {
      _addMessage('❌ Error: Hindi makakonekta sa Gemini.', isUserMessage: false);
      print("Error details: $e");
    } finally {
      if (mounted) { // Check kung nandoon pa sa screen ang user
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addMessage(String text, {required bool isUserMessage}) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUserMessage: isUserMessage,
        timestamp: DateTime.now(),
      ));
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar color is now matching the gradient better
      appBar: AppBar(
        title: const Text(
          'Gemini AI',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent, // Solid blue para sa top
        elevation: 0, // Tinanggal ang shadow para sa seamless look
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blueAccent, // Mula sa kulay ng AppBar
              Color(0xFFE3F2FD), // Papuntang light blue/white sa baba
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? const Center(
                child: Text(
                  'Mag-send ng message para magsimula!',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              )
                  : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return MessageBubble(message: _messages[index]);
                },
              ),
            ),

            // Loading Indicator
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: const [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Nag-iisip si Gemini...',
                      style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),

            // Input Bar
            InputBar(onSendMessage: _handleSend),
          ],
        ),
      ),
    );
  }
}