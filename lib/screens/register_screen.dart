import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'choose_cat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/step_provider.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() => _isLoading = true);

    try {
      // 1. 创建 Firebase Auth 用户
      final credential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;
      if (user == null) throw Exception("User is null after registration");

      // 2. 写入 Firestore users collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'email': user.email,
        'nickname': '',
        'cat': null,
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;

      //3. 处理步数 
      final stepProvider =
          Provider.of<StepProvider>(context, listen: false);

      stepProvider.resetSteps();          // 清空上一个账号的步数
      await stepProvider.loadSavedSteps(); // 加载新账号的步数（一般为0）
      stepProvider.startListening();       // 开始监听新账号的步数


      // 4. 跳转到选猫页面
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChooseCatScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(e.message ?? 'Failed to Register');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    // appBar: AppBar(title: const Text('Register')),

    body: Stack(
      children: [
        // 1️⃣ 背景图
        Positioned.fill(
          child: Image.asset(
            'assets/images/login.jpeg',
            fit: BoxFit.cover,
          ),
        ),

        // 2️⃣ 半透明遮罩（保证输入框可见）
        Positioned.fill(
          child: Container(
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),

        // 3️⃣ 主体内容
       Align(
  alignment: Alignment.bottomCenter,
          child: Padding(
    padding: const EdgeInsets.only(bottom: 120), 
            child: Column(
              mainAxisSize: MainAxisSize.min,
              
              children: [
                 const SizedBox(height: 20),

                

                // Email 输入框
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),

                // Password 输入框
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                // Register 按钮
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEEBF6D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 14),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Register'),
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
