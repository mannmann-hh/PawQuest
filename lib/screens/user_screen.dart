import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'choose_cat_screen.dart';
import 'notifications_screen.dart';
import '../widgets/custom_bottom_bar.dart';
import 'main_screen.dart';
import 'login_screen.dart';
import 'package:provider/provider.dart';
import 'package:pawquest/providers/step_provider.dart';


class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  User? user = FirebaseAuth.instance.currentUser;

  Future<void> _changeDisplayName(BuildContext context) async {
    final controller = TextEditingController(text: user?.displayName ?? '');

    final confirm = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modify User Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New User Name',
            hintText: 'Please enter your new name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirm != null && confirm.isNotEmpty) {
      await user?.updateDisplayName(confirm);
      await user?.reload();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'nickname': confirm});

      if (!mounted) return;

      setState(() {
        user = FirebaseAuth.instance.currentUser;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated successfully')),
      );
    }
  }

  Future<void> _updateCatAvatar(String newCat) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .update({'cat': newCat});

    setState(() {
      user = FirebaseAuth.instance.currentUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, userSnapshot) {
        final currentUser = userSnapshot.data;

        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ----------------- Guest Mode (登录前) -----------------
        if (currentUser == null) {
          return Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    "assets/images/profiles_bg.jpeg",
                    fit: BoxFit.cover,
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('You are currently in Guest Mode.',
                            style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: const Text('Login'),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // ----------------- User Logged In -----------------
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>?;
            final email = data?['email'] ?? 'Unknown';
            final nickname =
                data?['nickname'] ?? user?.displayName ?? 'Unnamed';
            final cat = data?['cat'] ?? 'cat1';

            final imagePath = 'assets/images/cats_profile/$cat.jpeg';

            return Scaffold(
              body: Stack(
                children: [
                  /// ⭐ 背景图（固定不动）
                  Positioned.fill(
                    child: Image.asset(
                      "assets/images/profiles_bg.jpeg",
                      fit: BoxFit.cover,
                    ),
                  ),

                  SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: 12),

                        /// ⭐ 顶部 title image（profiles.png）
                        Image.asset(
                          "assets/images/title/profiles.png",
                          height: 120,
                          fit: BoxFit.contain,
                        ),

                        const SizedBox(height: 10),

                        // ---------------- Profile Content ----------------
                        Expanded(
                          child: SingleChildScrollView(
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width, // ⭐ 必须加
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 20),
                                  CircleAvatar(
                                    radius: 48,
                                    backgroundImage: AssetImage(imagePath),
                                  ),
                                  const SizedBox(height: 16),
                                  Text("Username: $nickname",
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  Text("E-mail: $email",
                                      style: const TextStyle(fontSize: 16)),
                                  const SizedBox(height: 8),
                                  _buildStyledButton(
                                      context,
                                      "Notifications",
                                      () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const NotificationsScreen()),
                                          ),
                                      const Color(0xFFEE9B8C)),
                                  const SizedBox(height: 12),
                                  _buildStyledButton(
                                      context,
                                      "Modify User Name",
                                      () => _changeDisplayName(context),
                                      Colors.amber),
                                  const SizedBox(height: 12),
                                  _buildStyledButton(
                                      context, "Change cat character",
                                      () async {
                                    final selectedCat = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const ChooseCatScreen()),
                                    );
                                    if (selectedCat != null) {
                                      await _updateCatAvatar(selectedCat);
                                    }
                                  }, Colors.amber),
                                  const SizedBox(height: 12),
                                  _buildStyledButton(
                                    context,
                                    "Logout",
                                    () async {
                                      // ⭐ 1. 获取 StepProvider
                                      final sp = context.read<StepProvider>();

                                      // ⭐ 2. 停止 pedometer 监听
                                      sp.disposeListener();

                                      // ⭐ 3. 清空当前步数
                                      sp.resetSteps();

                                      // ⭐ 4. 退出 Firebase 登录
                                      await FirebaseAuth.instance.signOut();

                                      if (!mounted) return;

                                      // ⭐ 5. 跳转回登录界面
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const LoginScreen()),
                                      );
                                    },
                                    const Color(0xff6DB4D6),
                                  ),
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: CustomBottomBar(
                currentIndex: 4,
                onTap: (index) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MainScreen(initialIndex: index),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  /// ---------------- Reusable Cute Button ----------------
  Widget _buildStyledButton(
    BuildContext context,
    String text,
    VoidCallback onPressed,
    Color color,
  ) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.7,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.brown,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        child: Text(text),
      ),
    );
  }
}
