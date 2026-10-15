import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'services/sessao.dart';

class _ChatMessage {
  final String role;
  String content;
  _ChatMessage({required this.role, required this.content});
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
  WebSocketChannel? _channel;

  static const String _iaBaseUrl = String.fromEnvironment(
    'IA_BASE_URL',
    defaultValue: 'http://127.0.0.1:8001',
  );

  String get _wsUrl => '${_iaBaseUrl.replaceFirst('http', 'ws')}/ws/chat';

  @override
  void initState() {
    super.initState();
    _conectarWebSocket();
  }

  void _conectarWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _channel!.stream.listen(
        (message) {

          if (!mounted) return;
          final data = jsonDecode(message);
          if (data['error'] != null) {
            _adicionarErro(data['error']);
            setState(() => _isLoading = false);
          } else if (data['token'] != null) {
            setState(() {
              if (_isLoading) {
                _isLoading = false;
                _messages.add(_ChatMessage(role: 'assistant', content: ''));
              }
              _messages.last.content += data['token'] as String;
            });
            _scrollToBottom();
          } else if (data['done'] == true) {
            setState(() => _isLoading = false);
            _scrollToBottom();
          }
        },
        onError: (error) {
          if (!mounted) return;
          _adicionarErro('Erro na conexão WebSocket.');
          setState(() => _isLoading = false);
        },
        onDone: () {
          if (!mounted) return;
          setState(() => _isLoading = false);
        },
      );
    } catch (e) {
      _adicionarErro('Falha ao inicializar WebSocket.');
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _enviarMensagem() {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _isLoading) return;

    if (_channel == null || _channel?.closeCode != null) {
      _conectarWebSocket();
    }

    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: texto));
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    final payload = jsonEncode({
      'mensagem': texto,
      'usuario_id': Sessao.usuarioId,
      'historico': _messages
          .sublist(0, _messages.length - 1)
          .map((m) => m.toJson())
          .toList(),
    });

    _channel?.sink.add(payload);
  }

  void _adicionarErro(String msg) {
    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(role: 'assistant', content: '⚠️ $msg'));
    });
  }

  bool _scrollAgendado = false;

  void _scrollToBottom() {
    if (_scrollAgendado) return;
    _scrollAgendado = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollAgendado = false;
      if (mounted && _scrollController.hasClients) {
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
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

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
                    child: IconButton(
                      icon: const Icon(
                        Icons.keyboard_return,
                        color: Colors.black,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: isKeyboardOpen ? 40 : 120,
                  curve: Curves.easeInOut,
                  child: Image.asset(
                    'assets/ekologo.png',
                    colorBlendMode: BlendMode.screen,
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: isKeyboardOpen ? 4 : 16,
                ),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  style: TextStyle(
                    fontSize: isKeyboardOpen ? 24 : 48,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF5AC8FA),
                    fontFamily: 'ComicSans',
                  ),
                  child: const Text('EkoIA'),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: isKeyboardOpen ? 8 : 20,
                ),
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
          'Pergunte algo',
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
            Text('EkoIA está pensando...', style: TextStyle(fontSize: 13)),
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
                hintText: 'Pergunte à EkoIA...',
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
