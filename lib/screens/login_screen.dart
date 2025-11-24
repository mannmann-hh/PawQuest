import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_screen.dart'; // User successfully login and redirected to the profile
import 'register_screen.dart';




class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const  MainScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Login failed');
    } finally {
      setState(() => _isLoading = false);
    }
  }


  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    

    body: Stack(
      children: [
        // 1️⃣  背景图
        Positioned.fill(
          child: Image.asset(
            'assets/images/login.jpeg', // 你的背景
            fit: BoxFit.cover,
          ),
        ),

        // 2️⃣  半透明白色遮罩（确保输入框可见）
        Positioned.fill(
          child: Container(
            color: Colors.white.withOpacity(0.4),
          ),
        ),

        // 3️⃣  
        Align(
  alignment: Alignment.bottomCenter,
  child: Padding(
    padding: const EdgeInsets.only(bottom: 100), // 控制整体高度
    child: Column(
      mainAxisSize: MainAxisSize.min,   // ⭐⭐ 关键：让 Column 不占满屏
      children: [
        
        const SizedBox(height: 20),

        // Email
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),

        // Password
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: 'Password',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 16),

        // Login button
        _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEEBF6D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 14),
                  shape: const StadiumBorder(),
                ),
                child: const Text('Login'),
              ),
        const SizedBox(height: 12),

        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            );
          },
          child: const Text(
            'Don’t have an account? Register',
            style: TextStyle(color: Colors.brown),
          ),
        ),
      ],
    ),
  ),
),

      ],
    ),
  );
}

}
