import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AdminLoginView extends StatefulWidget {
  const AdminLoginView({super.key});

  @override
  State<AdminLoginView> createState() => _AdminLoginViewState();
}

class _AdminLoginViewState extends State<AdminLoginView> {
  final _controller = TextEditingController();
  String? _error;

  // NOTE: for production, replace this with real auth.
  static const _devPassword = 'admin123';

  void _submit() {
    final txt = _controller.text.trim();
    if (txt == _devPassword) {
      AuthService.setAdmin(true);
      AuthService.setLoggedIn(true);
      Navigator.of(context).pushReplacementNamed('/app');
    } else {
      setState(() => _error = 'Invalid password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login'), backgroundColor: const Color(0xFF2563EB)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Enter admin password to access admin panel.'),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password', errorText: _error),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _submit, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)), child: const Text('Sign in')),
            const SizedBox(height: 12),
            const Text('Development note: password is "admin123". Replace with real auth in production.'),
          ],
        ),
      ),
    );
  }
}
