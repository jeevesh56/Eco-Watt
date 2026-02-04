import 'package:flutter/material.dart';
import 'dart:ui';

import '../../app/routes.dart';
import '../../app/state_container.dart';

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
  final _confirmPasswordCtrl = TextEditingController();
  bool isLogin = true;
  bool showPassword = false;
  bool _busy = false;

  late final AnimationController _bgController;
  late final Animation<double> _bgAnimation;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat(reverse: true);
    _bgAnimation = CurvedAnimation(
      parent: _bgController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Calm, innovative background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF020617), // deep navy
                  Color(0xFF0F172A), // slate
                  Color(0xFF0EA5E9), // cyan accent
                ],
              ),
            ),
          ),
          // soft blurred circles for a modern, calm feel with subtle motion
          AnimatedBuilder(
            animation: _bgAnimation,
            builder: (context, child) {
              final dy = 24 * (_bgAnimation.value - 0.5);
              return Stack(
                children: [
                  Positioned(
                    top: -80 + dy,
                    left: -40,
                    child: const _BlurCircle(
                      color: Color(0xFF38BDF8),
                      size: 220,
                    ),
                  ),
                  Positioned(
                    bottom: -120 - dy,
                    right: -60,
                    child: const _BlurCircle(
                      color: Color(0xFF22C55E),
                      size: 260,
                    ),
                  ),
                ],
              );
            },
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
                'Email',
                Icons.person_outline,
                controller: _usernameCtrl,
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return 'Enter email';
                  final emailOk = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
                  if (!emailOk) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _passwordField(),
              if (!isLogin) ...[
                const SizedBox(height: 12),
                _confirmPasswordField(),
              ],
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
      keyboardType: hint.toLowerCase().contains('email')
          ? TextInputType.emailAddress
          : TextInputType.text,
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
      onFieldSubmitted: (_) => _loginUser(),
    );
  }

  Widget _confirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordCtrl,
      obscureText: true,
      validator: (v) {
        if (isLogin) return null;
        final confirm = v ?? '';
        if (confirm.isEmpty) return 'Confirm your password';
        if (confirm != _passwordCtrl.text) return 'Passwords do not match';
        return null;
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.green),
        hintText: 'Confirm Password',
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onFieldSubmitted: (_) => _registerUser(),
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
        onPressed: _busy
            ? null
            : () async {
                if (isLogin) {
                  await _loginUser();
                } else {
                  await _registerUser();
                }
              },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            _busy ? 'Please wait...' : (isLogin ? 'Login' : 'Create Account'),
            key: ValueKey(isLogin),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }


  Future<void> _loginUser() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _usernameCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email or password')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final state = AppStateScope.of(context);
      final result =
          await state.auth.loginUser(email: email, password: password);
      if (!mounted) return;
      if (result.ok) {
        await state.bills.load(userId: result.userId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful')),
        );
        Navigator.of(context).pushReplacementNamed(AppRoutes.root);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email or password')),
        );
      }
    } catch (e, st) {
      debugPrint('[Auth] Login error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email or password')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _registerUser() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _usernameCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email and password')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final state = AppStateScope.of(context);
      final result = await state.auth.registerUser(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );
      if (!mounted) return;
      if (result.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully')),
        );
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account already exists')),
        );
      }
    } catch (e, st) {
      debugPrint('[Auth] Register error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account already exists')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// Soft blurred circle used in the background for a calm, innovative look.
class _BlurCircle extends StatelessWidget {
  final Color color;
  final double size;

  const _BlurCircle({
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}
