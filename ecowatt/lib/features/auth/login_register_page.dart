import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/routes.dart';

/// Creative combined Login / Register page for the app.
/// Placed under `lib/features/auth`.
class LoginRegisterPage extends StatefulWidget {
  const LoginRegisterPage({super.key});

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool isLogin = true;
  bool showPassword = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Decorative background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEDF7F0), Color(0xFFE7F0FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.04),
                borderRadius: BorderRadius.circular(140),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  _logo(),
                  const SizedBox(height: 26),
                  _card(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logo() {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          tween: Tween(begin: 0.9, end: 1.0),
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: child,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                )
              ],
            ),
            child: const Icon(Icons.eco, size: 64, color: Color(0xFF2E7D32)),
          ),
        ),
        const SizedBox(height: 12),
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF0D47A1)],
          ).createShader(rect),
          child: const Text(
            'EcoWatt',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isLogin ? 'Welcome back 👋' : 'Create your account',
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    );
  }

  Widget _card() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: Form(
        key: _formKey,
        child: Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 520),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      isLogin ? 'Login' : 'Register',
                      key: ValueKey(isLogin),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isLogin = !isLogin;
                      });
                    },
                    child: Text(isLogin ? 'Create account' : 'Have account'),
                  )
                ],
              ),
              const SizedBox(height: 16),
              _textField(
                'Username',
                Icons.person_outline,
                controller: _usernameCtrl,
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) return 'Enter username';
                  if (s.length < 3) return 'Username must be at least 3 characters';
                  if (!RegExp(r'^[A-Za-z][A-Za-z0-9]*$').hasMatch(s)) {
                    return 'Username must start with a letter and contain only letters and numbers';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _passwordField(),
              const SizedBox(height: 18),
              _actionButton(),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reset password (stub)')),
                    );
                  },
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField(
    String hint,
    IconData icon, {
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.green[700]),
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _passwordField() {
    return TextFormField(
      controller: _passwordCtrl,
      obscureText: !showPassword,
      validator: (v) => (v == null || v.length < 6)
          ? 'Password must be at least 6 characters'
          : null,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.green),
        hintText: 'Password',
        suffixIcon: IconButton(
          icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              showPassword = !showPassword;
            });
          },
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onFieldSubmitted: (_) => _submit(),
    );
  }

  Widget _actionButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _submit,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            isLogin ? 'Login' : 'Create Account',
            key: ValueKey(isLogin),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }



  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (isLogin) {
      final ok = await _loginUser(username, password);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful')),
        );
        Navigator.of(context).pushReplacementNamed(AppRoutes.root);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid username or password')),
        );
      }
    } else {
      final registered = await _registerUser(username, password);
      if (!mounted) return;
      if (registered) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful. Please login.')),
        );
        setState(() {
          isLogin = true;
          _passwordCtrl.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username already exists')),
        );
      }
    }
  }

  Future<bool> _registerUser(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users') ?? '{}';
    final Map<String, dynamic> temp = jsonDecode(usersJson) as Map<String, dynamic>;
    final users = temp.map((k, v) => MapEntry(k, v as String));

    if (users.containsKey(username)) return false;
    final newUsers = Map<String, String>.from(users)..[username] = password;
    await prefs.setString('users', jsonEncode(newUsers));
    return true;
  }

  Future<bool> _loginUser(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users') ?? '{}';
    final Map<String, dynamic> temp = jsonDecode(usersJson) as Map<String, dynamic>;
    final users = temp.map((k, v) => MapEntry(k, v as String));

    final stored = users[username];
    return stored != null && stored == password;
  }
}

