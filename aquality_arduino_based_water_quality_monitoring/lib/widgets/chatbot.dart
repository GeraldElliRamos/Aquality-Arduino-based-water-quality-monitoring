import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// Disable SSL certificate verification for testing (remove in production)
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class AqualityChatbot extends StatefulWidget {
  const AqualityChatbot({super.key});

  @override
  State<AqualityChatbot> createState() => _AqualityChatbotState();
}

class _AqualityChatbotState extends State<AqualityChatbot> {
  bool _isOpen = false;
  Offset _position = const Offset(0, 80);
  static const double _windowHeight = 450;
  static const double _windowWidth = 320;
  static const double _buttonSize = 56;
  static const double _windowPadding = 16;

  void _toggle() => setState(() => _isOpen = !_isOpen);
  void _close() => setState(() => _isOpen = false);

  void _updatePosition(DragUpdateDetails details) {
    final size = MediaQuery.of(context).size;
    final newX = _position.dx + details.delta.dx;
    final newY = _position.dy + details.delta.dy;

    setState(() {
      _position = Offset(
        newX.clamp(0, size.width - _buttonSize),
        newY.clamp(0, size.height - _buttonSize),
      );
    });
  }

  Offset _getWindowPosition(Size screenSize) {
    double left = _position.dx - (_windowWidth - _buttonSize) / 2;
    double top = _position.dy - _windowHeight - _windowPadding;

    // Adjust horizontal position to stay within bounds
    if (left < _windowPadding) {
      left = _windowPadding;
    } else if (left + _windowWidth > screenSize.width) {
      left = screenSize.width - _windowWidth - _windowPadding;
    }

    // If window goes above screen, position it below the button instead
    if (top < _windowPadding) {
      top = _position.dy + _buttonSize + _windowPadding;
    }

    // Ensure it doesn't go below the screen (clamp to available space)
    top = top.clamp(
      _windowPadding,
      screenSize.height - _windowHeight - _windowPadding,
    );

    return Offset(left, top);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final windowPos = _getWindowPosition(screenSize);

    return Stack(
      children: [
        Positioned(
          left: windowPos.dx,
          top: windowPos.dy,
          child: Offstage(
            offstage: !_isOpen,
            child: _ChatWindow(onClose: _close),
          ),
        ),
        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: GestureDetector(
            onPanUpdate: _updatePosition,
            child: FloatingActionButton(
              heroTag: 'chatbot',
              backgroundColor: const Color(0xFF06B6D4),
              onPressed: _toggle,
              child: Icon(
                _isOpen ? Icons.close : Icons.water_drop,
                color: Colors.white,
                size: 28,
              ),
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
  String _quotaLabel = '';

  static const String _welcomeMessage =
      'Hi! I\'m Aqua 🌊 your Aquality assistant. I can help you understand the dashboard, trends, alerts, history, settings, and profile modules. What would you like to know?';

  static const String _systemPrompt = '''
You are Aqua, a helpful assistant for the Aquality app — an Arduino-based water quality monitoring system for freshwater tilapia ponds.

You help users understand and use the app's modules:

📊 DASHBOARD
- Shows real-time water quality readings from Arduino sensors
- Displays pH, temperature, ammonia, and turbidity levels
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
- Ammonia: 0.00 - 0.02 mg/L
- Turbidity: below 30 NTU

Keep responses concise, friendly, and helpful. Use emojis sparingly.
''';

  @override
  void initState() {
    super.initState();
    // Enable HTTPS for Windows development
    HttpOverrides.global = MyHttpOverrides();
    _messages.add({'role': 'assistant', 'content': _welcomeMessage});
    _refreshQuotaStatus();
  }

  Future<void> _refreshQuotaStatus() async {
    try {
      final response = await http
          .get(Uri.parse('http://localhost:3000/health'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return;

      final quota = decoded['quota'];
      if (quota is! Map) return;

      final remaining = quota['remaining'];
      final resetInSeconds = quota['resetInSeconds'];
      if (remaining is! Map || resetInSeconds is! Map) return;

      final minuteLeft = remaining['minute'];
      final dayLeft = remaining['day'];
      final minuteReset = resetInSeconds['minute'];

      if (minuteLeft is num &&
          dayLeft is num &&
          minuteReset is num &&
          mounted) {
        setState(() {
          _quotaLabel =
              'Free tier left: ${minuteLeft.toInt()}/min, ${dayLeft.toInt()}/day (reset ${minuteReset.toInt()}s)';
        });
      }
    } catch (_) {
      // Keep UI quiet if health endpoint is temporarily unavailable.
    }
  }

  void _startNewChat() {
    setState(() {
      _messages
        ..clear()
        ..add({'role': 'assistant', 'content': _welcomeMessage});
      _isLoading = false;
    });
    _controller.clear();
    _scrollToBottom();
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

  String _buildOfflineAnswer(String question) {
    final q = question.toLowerCase();

    if (q.contains('dashboard')) {
      return 'The Dashboard shows real-time readings from your sensors: pH, temperature, ammonia, and turbidity. Colors indicate status (green safe, yellow warning, red critical).';
    }
    if (q.contains('trend')) {
      return 'Trends lets you view historical water quality data over time. You can filter by day, week, or month to spot patterns and anomalies.';
    }
    if (q.contains('alert')) {
      return 'Alerts show when readings go out of safe ranges. You can review severity levels and mark alerts as read/dismissed.';
    }
    if (q.contains('history')) {
      return 'History keeps a full record of readings. You can search/filter records and export data for reports.';
    }
    if (q.contains('setting')) {
      return 'Settings allows threshold configuration, notification preferences, and theme/language options.';
    }
    if (q.contains('profile')) {
      return 'Profile shows your account info and role (Tilapia Farmer, Fish Pond Owner, or LGU), and lets you update personal details.';
    }
    if (q.contains('safe') || q.contains('range') || q.contains('tilapia')) {
      return 'Typical tilapia ranges: pH 6.5-8.5, temperature 25-32 C, ammonia 0.00-0.02 mg/L, turbidity below 30 NTU.';
    }

    return 'I can still help while the cloud AI is unavailable. Ask about: dashboard, trends, alerts, history, settings, profile, or safe tilapia ranges.';
  }

  String _extractErrorDetail(dynamic body, String fallback) {
    if (body is Map) {
      final details = body['details'];
      if (details is String && details.trim().isNotEmpty) return details;

      final message = body['message'];
      if (message is String && message.trim().isNotEmpty) return message;

      final error = body['error'];
      if (error is String && error.trim().isNotEmpty) return error;
      if (error is Map) {
        final errMessage = error['message'];
        if (errMessage is String && errMessage.trim().isNotEmpty) {
          return errMessage;
        }
      }
    }
    return fallback;
  }

  String _formatQuotaStatus(dynamic body) {
    if (body is! Map) return '';
    final quota = body['quota'];
    if (quota is! Map) return '';

    final remaining = quota['remaining'];
    final resetInSeconds = quota['resetInSeconds'];
    if (remaining is! Map || resetInSeconds is! Map) return '';

    final minuteLeft = remaining['minute'];
    final dayLeft = remaining['day'];
    final minuteReset = resetInSeconds['minute'];

    if (minuteLeft is num && dayLeft is num && minuteReset is num) {
      return '\n\nFree-tier status:\n- Requests left this minute: $minuteLeft\n- Requests left today: $dayLeft\n- Minute reset in: ${minuteReset}s';
    }

    return '';
  }

  String? _getHardcodedAnswer(String question) {
    final q = question.toLowerCase().trim();

    if (q == 'hi' || q == 'hello' || q == 'hey') {
      return 'Hi! I am Aqua, your Aquality assistant. Ask me about dashboard, alerts, trends, history, settings, or safe water ranges for tilapia.';
    }

    if (q.contains('what is aquality') || q.contains('what is this app')) {
      return 'Aquality is an Arduino-based water quality monitoring app for freshwater tilapia ponds. It tracks key parameters and helps you respond quickly to risky changes.';
    }

    if (q == 'modules' ||
        q.contains('what are the modules') ||
        q.contains('explain modules')) {
      return 'Aquality modules:\n1. Dashboard - Live sensor readings and current system status.\n2. Trends - Historical charts to see water quality patterns over time.\n3. Alerts - Warnings when parameters go out of safe range.\n4. History - Full log of past readings for review and reporting.';
    }

    if (q == 'dashboard' ||
        q.contains('what is dashboard') ||
        q.contains('explain dashboard')) {
      return 'Dashboard shows real-time pH, temperature, ammonia, and turbidity readings, plus status indicators so you can quickly check if pond conditions are safe.';
    }

    if (q == 'trends' ||
        q.contains('what is trends') ||
        q.contains('explain trends')) {
      return 'Trends shows historical charts of your water parameters. Use it to track patterns by day, week, or month and spot changes early.';
    }

    if (q == 'alerts' ||
        q.contains('what is alerts') ||
        q.contains('explain alerts')) {
      return 'Alerts lists notifications when a parameter becomes unsafe. It helps you respond quickly before conditions affect fish health.';
    }

    if (q == 'history' ||
        q.contains('what is history') ||
        q.contains('explain history')) {
      return 'History stores previous water quality readings so you can review, filter, and use records for monitoring and reports.';
    }

    if (q.contains('safe ph') ||
        (q.contains('ph') && q.contains('tilapia')) ||
        q.contains('ph range')) {
      return 'Safe pH for tilapia is usually 6.5 to 8.5.';
    }

    if (q.contains('safe temperature') ||
        (q.contains('temperature') && q.contains('tilapia')) ||
        q.contains('temp range')) {
      return 'Safe temperature for tilapia is around 25 C to 32 C.';
    }

    if (q.contains('ammonia') || q.contains('nh3')) {
      return 'Keep ammonia very low, ideally around 0.00 to 0.02 mg/L for safer tilapia conditions.';
    }

    if (q.contains('turbidity')) {
      return 'Recommended turbidity is below 30 NTU for better water quality conditions.';
    }

    if (q.contains('who are you')) {
      return 'I am Aqua, the Aquality Assistant. I help explain your water quality data and app features.';
    }

    if (q.contains('how to use') || q.contains('how do i use')) {
      return 'Start from Dashboard for live readings, check Alerts for warnings, view Trends/History for analysis, then adjust thresholds in Settings.';
    }

    return null;
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    _controller.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _scrollToBottom();

    final hardcodedReply = _getHardcodedAnswer(text);
    if (hardcodedReply != null) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': hardcodedReply});
        _isLoading = false;
      });
      await _refreshQuotaStatus();
      _scrollToBottom();
      return;
    }

    final apiMessages = _messages
        .where((m) => m['role'] == 'user' || m['role'] == 'assistant')
        .map(
          (m) => {
            'role': (m['role'] ?? 'user').toString(),
            'content': (m['content'] ?? '').toString(),
          },
        )
        .toList();

    while (apiMessages.isNotEmpty && apiMessages.first['role'] != 'user') {
      apiMessages.removeAt(0);
    }

    try {
      final response = await http
          .post(
            Uri.parse('http://localhost:3000/api/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'messages': apiMessages,
              'systemPrompt': _systemPrompt,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Invalid server response format');
        }

        final data = decoded;
        final isSuccess = data['success'] == true;
        if (isSuccess) {
          String? reply;

          if (data['reply'] is String &&
              (data['reply'] as String).trim().isNotEmpty) {
            reply = data['reply'] as String;
          }

          if (reply == null) {
            final legacyData = data['data'];
            if (legacyData is Map) {
              final content = legacyData['content'];
              if (content is List && content.isNotEmpty) {
                final first = content.first;
                if (first is Map &&
                    first['text'] is String &&
                    (first['text'] as String).trim().isNotEmpty) {
                  reply = first['text'] as String;
                }
              }
            }
          }

          final safeReply = reply ?? _buildOfflineAnswer(text);
          setState(() {
            _messages.add({'role': 'assistant', 'content': safeReply});
          });
        } else {
          final message = _extractErrorDetail(data, 'Unknown server response');
          setState(() {
            _messages.add({'role': 'assistant', 'content': 'Error: $message'});
          });
        }
      } else if (response.statusCode == 400) {
        print('API 400 Error: ${response.body}');
        String details = 'Cloud AI is temporarily unavailable.';
        try {
          final body = jsonDecode(response.body);
          details = _extractErrorDetail(body, details);
        } catch (_) {}

        final fallback = _buildOfflineAnswer(text);
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': '$details\n\nOffline answer:\n$fallback',
          });
        });
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print('API Auth Error: ${response.statusCode} - ${response.body}');
        String details = 'Authentication failed';
        try {
          final body = jsonDecode(response.body);
          details = _extractErrorDetail(body, details);
        } catch (_) {}
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': 'Authentication failed: $details',
          });
        });
      } else if (response.statusCode == 429) {
        print('API Quota Error: ${response.body}');
        String details = 'Quota exceeded for Gemini API.';
        String quotaInfo = '';
        try {
          final body = jsonDecode(response.body);
          details = _extractErrorDetail(body, details);
          quotaInfo = _formatQuotaStatus(body);
        } catch (_) {}

        final fallback = _buildOfflineAnswer(text);
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': '$details$quotaInfo\n\nOffline answer:\n$fallback',
          });
        });
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content':
                'Server error (${response.statusCode}). Is the backend running on localhost:3000?',
          });
        });
      }
    } on SocketException catch (e) {
      print('Socket error: $e');
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content':
              '❌ Connection error: ${e.message}\n\nMake sure the backend proxy is running:\nRun `npm install && npm start` in the backend/ folder',
        });
      });
    } on TimeoutException {
      print('Request timeout');
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content':
              '⏱️ Request timed out (20s). The API took too long to respond. Try again.',
        });
      });
    } catch (e) {
      print('Chatbot error details: $e');
      print('Error type: ${e.runtimeType}');
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content':
              '❌ Error connecting to backend:\n$e\n\nFix:\n1. Run `npm install` in backend/ folder\n2. Run `npm start` to start the backend\n3. Make sure it\'s running on localhost:3000',
        });
      });
    } finally {
      setState(() => _isLoading = false);
      await _refreshQuotaStatus();
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
                      Icons.add_comment_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    tooltip: 'New chat',
                    onPressed: _startNewChat,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 6),
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
                  final content = msg['content'] ?? '';
                  return _buildMessage(content, isUser, isDark);
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
            if (_quotaLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                child: Text(
                  _quotaLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
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
