import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme; // 可选：从上层传入主题切换

  const SplashScreen({super.key, this.onToggleTheme});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(Widget page) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 给深色背景，避免看起来像“白屏”
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeIn,
        child: Stack(
          children: [
            // 背景图
            Positioned.fill(
              child: Image.asset(
                'assets/images/logo.jpeg', 
                fit: BoxFit.cover,
              ),
            ),
            // // 半透明渐变遮罩，保证按钮和文字在亮背景上也清晰
            // Positioned.fill(
            //   child: Container(
            //     decoration: BoxDecoration(
            //       gradient: LinearGradient(
            //         begin: Alignment.topCenter,
            //         end: Alignment.bottomCenter,
            //         stops: const [0.0, 0.5, 1.0],
            //         colors: [
            //           Colors.black.withOpacity(0.35),
            //           Colors.black.withOpacity(0.45),
            //           Colors.black.withOpacity(0.55),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
            // 中心内容
            // 让按钮往下移：整个 Column 移到底部
Align(
  alignment: Alignment.bottomCenter,
  child: Padding(
    padding: const EdgeInsets.only(bottom: 115), 
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: () => _goTo(const LoginScreen()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFEEBF6D),
            foregroundColor: Color(0xFF6C4A2F),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(
              horizontal: 30,
              vertical: 10,
            ),
          ),
          child: const Text('Login'),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => _goTo(const RegisterScreen()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFEEBF6D),
            foregroundColor: Color(0xFF6C4A2F),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(
              horizontal: 30,
              vertical: 10,
            ),
          ),
          child: const Text('Register'),
        ),
      ],
    ),
  ),
),

          ],
        ),
      ),
    );
  }
}
