import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_screen.dart';
import 'register_screen.dart';
import 'package:provider/provider.dart';
import 'package:pawquest/providers/theme_provider.dart';
import 'package:pawquest/theme/app_palette.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final AuthService? authService;
  final VoidCallback? onLoginSuccess;
  final AppPalette? palette;

  const LoginScreen({
    super.key,
    this.authService,
    this.onLoginSuccess,
    this.palette,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AppPalette p = AppPalette.all.first;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late final AuthService _authService;
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? FirebaseAuthService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Login failed');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    p = widget.palette ?? context.watch<ThemeProvider>().palette;
    return Scaffold(
      backgroundColor: p.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/login.jpeg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withValues(alpha: 0.2)),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 56),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _field(
                      controller: _emailController,
                      hint: 'Email',
                      icon: Icons.email_rounded,
                      keyboard: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _field(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_rounded,
                      obscure: _obscure,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: p.text.withValues(alpha: 0.5),
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _primaryButton('Login', _login),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()),
                      ),
                      child: Text(
                        'Don’t have an account? Register',
                        style: TextStyle(
                            color: p.text, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      style: TextStyle(color: p.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: p.text.withValues(alpha: 0.4)),
        prefixIcon: Icon(icon, color: p.primary),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Text(label),
      ),
    );
  }
}
