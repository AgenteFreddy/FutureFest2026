import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class _ChatMessage {
  final String role;
  final String content;
  const _ChatMessage({required this.role, required this.content});
  Map<String, String> toJson() => {'role': role, 'content': content};
}

class IaEkoScreen extends StatefulWidget {
  const IaEkoScreen({super.key});
  @override
  State<IaEkoScreen> createState() => _IaEkoScreenState();
}

class _IaEkoScreenState extends State<IaEkoScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  static const String _iaBaseUrl = String.fromEnvironment(
    'IA_BASE_URL',
    defaultValue: 'http://127.0.0.1:8001',
  );
  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _enviarMensagem() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _isLoading) return;
    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: texto));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();
    try {
      final response = await http
          .post(
            Uri.parse('$_iaBaseUrl/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'mensagem': texto,
              'historico': _messages.map((m) => m.toJson()).toList(),
            }),
          )
          .timeout(const Duration(seconds: 120));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.add(
            _ChatMessage(role: 'assistant', content: data['resposta'] ?? ''),
          );
        });
      } else {
        _adicionarErro('Erro do servidor (${response.statusCode}).');
      }
    } catch (e) {
      _adicionarErro(
        'Não foi possível conectar à IA Eko.\n'
        'Verifique se o backend está rodando:\n'
        'uvicorn ia_eko_api:app --port 8001',
      );
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _adicionarErro(String msg) {
    setState(() {
      _messages.add(_ChatMessage(role: 'assistant', content: '⚠️ $msg'));
    });
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
      backgroundColor: const Color(0xFFE8F5E9),
      body: Stack(
        children: [
          Positioned(
            top: -20,
            left: -20,
            child: Image.asset(
              'assets/canto2ekobelth.png',
              width: 300,
              colorBlendMode: BlendMode.screen,
            ),
          ),
          Positioned(
            top: -40,
            right: -40,
            child: Image.asset('assets/bolinhaekobelth.png', width: 180),
          ),
          Positioned(
            bottom: -20,
            right: -20,
            child: Image.asset(
              'assets/cantoekobelth.png',
              width: 300,
              colorBlendMode: BlendMode.screen,
            ),
          ),
          Positioned(
            bottom: 20,
            left: -10,
            child: Image.asset('assets/folhaekobelth.png', width: 100),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, left: 16.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.deepPurpleAccent,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.keyboard_return,
                          color: Colors.black,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),
                Image.asset(
                  'assets/ekologo.png',
                  height: 120,
                  colorBlendMode: BlendMode.screen,
                ),
                const SizedBox(height: 16),
                const Text(
                  'IA Eko',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF5AC8FA),
                    fontFamily: 'ComicSans',
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(child: _buildChatBody()),
                _buildInputBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBody() {
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'Pergunte algo sobre saúde\ne cuidados com idosos 🌿',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) return _buildTypingIndicator();
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF4CAF50) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.content,
          style: TextStyle(
            fontSize: 15,
            color: isUser ? Colors.white : Colors.black87,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('IA Eko está pensando...', style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _enviarMensagem(),
              decoration: InputDecoration(
                hintText: 'Pergunte à IA Eko...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.85),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _isLoading ? null : _enviarMensagem,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade400,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(14),
              elevation: 3,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 22),
          ),
        ],
      ),
    );
  }
}
