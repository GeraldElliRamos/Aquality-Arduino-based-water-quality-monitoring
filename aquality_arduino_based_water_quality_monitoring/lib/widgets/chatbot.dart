import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AqualityChatbot extends StatefulWidget {
  const AqualityChatbot({super.key});

  @override
  State<AqualityChatbot> createState() => _AqualityChatbotState();
}

class _AqualityChatbotState extends State<AqualityChatbot> {
  bool _isOpen = false;

  void _toggle() => setState(() => _isOpen = !_isOpen);
  void _close() => setState(() => _isOpen = false);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_isOpen)
          Positioned(
            bottom: 80,
            right: 16,
            child: _ChatWindow(onClose: _close),
          ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'chatbot',
            backgroundColor: const Color(0xFF2563EB),
            onPressed: _toggle,
            child: Icon(
              _isOpen ? Icons.close : Icons.chat_bubble_outline,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatWindow extends StatefulWidget {
  final VoidCallback onClose;
  const _ChatWindow({required this.onClose});

  @override
  State<_ChatWindow> createState() => _ChatWindowState();
}

class _ChatWindowState extends State<_ChatWindow> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  // Replace with your actual OpenAI API key
  static const String _apiKey =
      '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';

  static const String _systemPrompt = '''
You are Aqua, a helpful assistant for the Aquality app — an Arduino-based water quality monitoring system for freshwater tilapia ponds.

You help users understand and use the app's modules:

📊 DASHBOARD
- Shows real-time water quality readings from Arduino sensors
- Displays pH, temperature, dissolved oxygen, and turbidity levels
- Color-coded indicators: green (safe), yellow (warning), red (critical)
- Auto-refreshes every few seconds

📈 TRENDS
- Shows historical charts of water quality over time
- Users can filter by day, week, or month
- Helps identify patterns and anomalies in water conditions

🔔 ALERTS
- Lists all triggered alerts when parameters go out of safe range
- Shows alert severity: low, medium, high
- Users can mark alerts as read or dismiss them

📋 HISTORY
- Complete log of all sensor readings
- Exportable data for reporting
- Searchable and filterable records

⚙️ SETTINGS
- Toggle dark/light mode
- Configure alert thresholds for each parameter
- Manage notification preferences
- Language settings (English/Filipino)

👤 PROFILE
- View and edit personal information
- Shows user role: Tilapia Farmer, Fish Pond Owner, or LGU
- Account statistics and quick actions

Safe water quality ranges for tilapia:
- pH: 6.5 - 8.5
- Temperature: 25°C - 32°C
- Dissolved Oxygen: above 5 mg/L
- Turbidity: below 30 NTU

Keep responses concise, friendly, and helpful. Use emojis sparingly.
''';

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'assistant',
      'content':
          'Hi! I\'m Aqua 🌊 your Aquality assistant. I can help you understand the dashboard, trends, alerts, history, settings, and profile modules. What would you like to know?',
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    if (_apiKey ==
        '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') {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content':
              'API key not configured. Replace _apiKey with your OpenAI API key.',
        });
      });
      return;
    }

    _controller.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await http
          .post(
            Uri.parse('https://api.openai.com/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': 'gpt-3.5-turbo',
              'messages': [
                {'role': 'system', 'content': _systemPrompt},
                ..._messages.map(
                  (m) => {'role': m['role'], 'content': m['content']},
                ),
              ],
              'max_tokens': 500,
              'temperature': 0.2,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'] as String;
        setState(() {
          _messages.add({'role': 'assistant', 'content': reply});
        });
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content':
                'Authentication failed (invalid key). Please verify your API key.',
          });
        });
      } else {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content':
                'Server responded ${response.statusCode}. Please try again.',
          });
        });
      }
    } on SocketException {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content':
              'No internet connection detected. Please connect and retry.',
        });
      });
    } on TimeoutException {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content':
              'Request timed out. Please check your network and try again.',
        });
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Unexpected error: $e'});
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 320,
        height: 450,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white24,
                    child: Text('🌊', style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aqua',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Aquality Assistant',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: widget.onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return _buildTypingIndicator(isDark);
                  }
                  final msg = _messages[index];
                  final isUser = msg['role'] == 'user';
                  return _buildMessage(msg['content']!, isUser, isDark);
                },
              ),
            ),

            // Input
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_isLoading,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Ask about any module...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade400,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(String content, bool isUser, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 12,
              backgroundColor: Color(0xFF2563EB),
              child: Text('🌊', style: TextStyle(fontSize: 10)),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF2563EB)
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isUser ? 12 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 12),
                ),
              ),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 13,
                  color: isUser
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black87),
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 12,
            backgroundColor: Color(0xFF2563EB),
            child: Text('🌊', style: TextStyle(fontSize: 10)),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: const SizedBox(
              width: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _TypingDot(delay: 0),
                  _TypingDot(delay: 200),
                  _TypingDot(delay: 400),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Color(0xFF2563EB),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
