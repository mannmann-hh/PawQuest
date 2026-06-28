import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:pawquest/providers/step_provider.dart';
import 'edit_profile_screen.dart';
import 'notifications_screen.dart';
import 'step_history_screen.dart';
import '../widgets/custom_bottom_bar.dart';
import 'main_screen.dart';
import 'login_screen.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  static const Color _cream = Color(0xFFFFF6EB);
  static const Color _yellow = Color(0xFFF8D66D);
  static const Color _orange = Color(0xFFF77F42);
  static const Color _brown = Color(0xFF6B4F3A);
  static const Color _danger = Color(0xFFE0795C);

  ImageProvider _avatar(String cat, String? url) {
    if (url != null && url.isNotEmpty) return NetworkImage(url);
    return AssetImage('assets/images/cats_profile/$cat.jpeg');
  }

  Future<void> _logout(BuildContext context) async {
    final sp = context.read<StepProvider>();
    sp.disposeListener();
    sp.resetSteps();
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'PawQuest',
      applicationVersion: '1.0.0',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset('assets/images/icons/custom_earth.png',
            width: 44, height: 44),
      ),
      children: const [
        SizedBox(height: 8),
        Text(
          'Walk to explore Italy, collect cities and unlock local food. '
          'Every step takes you somewhere new.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, userSnapshot) {
        final currentUser = userSnapshot.data;

        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: _cream,
            body: Center(child: CircularProgressIndicator(color: _orange)),
          );
        }

        if (currentUser == null) {
          return _guestMode(context);
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(
                backgroundColor: _cream,
                body: Center(child: CircularProgressIndicator(color: _orange)),
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>?;
            final email = data?['email'] ?? 'Unknown';
            final nickname =
                data?['nickname'] ?? currentUser.displayName ?? 'Unnamed';
            final cat = data?['cat'] ?? 'cat1';
            final avatarUrl = data?['avatarUrl'] as String?;

            return Scaffold(
              backgroundColor: _cream,
              body: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
                  children: [
                    _header(context, nickname, email, cat, avatarUrl),
                    const SizedBox(height: 24),
                    _settingsCard([
                      _row(Icons.edit_rounded, 'Edit profile', () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(
                              currentNickname: nickname,
                              currentCat: cat,
                              currentAvatarUrl: avatarUrl,
                            ),
                          ),
                        );
                      }),
                      _divider(),
                      _row(Icons.notifications_rounded, 'Notifications', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationsScreen()),
                        );
                      }),
                      _divider(),
                      _row(Icons.bar_chart_rounded, 'Step history', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const StepHistoryScreen()),
                        );
                      }),
                    ]),
                    const SizedBox(height: 16),
                    _settingsCard([
                      _row(Icons.info_outline_rounded, 'About PawQuest',
                          () => _showAbout(context)),
                    ]),
                    const SizedBox(height: 24),
                    _logoutButton(context),
                  ],
                ),
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

  // ----------------------------------------------------------------- pieces

  Widget _header(BuildContext context, String nickname, String email,
      String cat, String? avatarUrl) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _yellow, width: 3),
            ),
            child: CircleAvatar(
              radius: 46,
              backgroundColor: _yellow.withValues(alpha: 0.35),
              backgroundImage: _avatar(cat, avatarUrl),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            nickname,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _brown,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              fontSize: 14,
              color: _brown.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsCard(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(children: rows),
    );
  }

  Widget _row(IconData icon, String title, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _yellow.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: _orange),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _brown,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: _brown.withValues(alpha: 0.35)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() => Divider(
        height: 1,
        thickness: 1,
        indent: 68,
        endIndent: 16,
        color: _brown.withValues(alpha: 0.08),
      );

  Widget _logoutButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _logout(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _danger.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded,
                      size: 20, color: _danger),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Log out',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _danger,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _guestMode(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle_rounded,
                  size: 88, color: _orange),
              const SizedBox(height: 16),
              const Text(
                'You are in Guest Mode',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _brown),
              ),
              const SizedBox(height: 8),
              Text(
                'Log in to save your steps and profile.',
                style: TextStyle(
                    fontSize: 14, color: _brown.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
