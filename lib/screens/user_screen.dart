import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:pawquest/providers/step_provider.dart';
import 'package:pawquest/providers/theme_provider.dart';
import 'package:pawquest/theme/app_palette.dart';
import 'edit_profile_screen.dart';
import 'notifications_screen.dart';
import 'step_history_screen.dart';
import '../widgets/custom_bottom_bar.dart';
import 'responsive_main_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';

class UserScreen extends StatefulWidget {
  final AuthService? authService;
  final bool showBottomNavigation;

  const UserScreen({
    super.key,
    this.authService,
    this.showBottomNavigation = true,
  });

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  ImageProvider _avatar(String cat, String? url) {
    if (url != null && url.isNotEmpty) return NetworkImage(url);
    return AssetImage('assets/images/cats_profile/$cat.jpeg');
  }

  Future<void> _logout(BuildContext context) async {
    final sp = context.read<StepProvider>();
    await LogoutCoordinator(widget.authService ?? FirebaseAuthService()).logout(
      stopStepListener: sp.disposeListener,
      resetSteps: sp.resetSteps,
    );
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

  void _showThemePicker(BuildContext context, AppPalette current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        final theme = sheetCtx.watch<ThemeProvider>();
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Choose a theme',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A4A4A))),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: AppPalette.all.map((pal) {
                    final selected = pal.id == theme.currentId;
                    return ListTile(
                      onTap: () {
                        sheetCtx.read<ThemeProvider>().setPalette(pal.id);
                        Navigator.pop(sheetCtx);
                      },
                      leading: _swatch(pal),
                      title: Text(pal.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4A4A4A))),
                      trailing: selected
                          ? Icon(Icons.check_circle_rounded, color: pal.primary)
                          : null,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _swatch(AppPalette pal) {
    Widget dot(Color c) => Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black12),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [dot(pal.primary), dot(pal.accent), dot(pal.background)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, userSnapshot) {
        final currentUser = userSnapshot.data;

        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: p.background,
            body: Center(child: CircularProgressIndicator(color: p.primary)),
          );
        }

        if (currentUser == null) {
          return _guestMode(context, p);
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Scaffold(
                backgroundColor: p.background,
                body:
                    Center(child: CircularProgressIndicator(color: p.primary)),
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>?;
            final email = data?['email'] ?? 'Unknown';
            final nickname =
                data?['nickname'] ?? currentUser.displayName ?? 'Unnamed';
            final cat = data?['cat'] ?? 'cat1';
            final avatarUrl = data?['avatarUrl'] as String?;
            final bio = data?['bio'] as String?;
            final city = data?['city'] as String?;
            final age = data?['age'] as int?;

            return Scaffold(
              backgroundColor: p.background,
              body: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
                  children: [
                    _header(p, nickname, email, cat, avatarUrl,
                        bio: bio, city: city, age: age),
                    const SizedBox(height: 24),
                    _settingsCard(p, [
                      _row(p, Icons.edit_rounded, 'Edit profile', () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(
                              currentNickname: nickname,
                              currentCat: cat,
                              currentAvatarUrl: avatarUrl,
                              currentBio: bio,
                              currentCity: city,
                              currentAge: age,
                            ),
                          ),
                        );
                      }),
                      _divider(p),
                      _row(p, Icons.notifications_rounded, 'Notifications', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationsScreen()),
                        );
                      }),
                      _divider(p),
                      _row(p, Icons.bar_chart_rounded, 'Step history', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const StepHistoryScreen()),
                        );
                      }),
                    ]),
                    const SizedBox(height: 16),
                    _settingsCard(p, [
                      _row(p, Icons.palette_rounded, 'Theme',
                          () => _showThemePicker(context, p),
                          trailing: p.name),
                      _divider(p),
                      _row(p, Icons.info_outline_rounded, 'About PawQuest',
                          () => _showAbout(context)),
                    ]),
                    const SizedBox(height: 24),
                    _logoutButton(context, p),
                  ],
                ),
              ),
              bottomNavigationBar: widget.showBottomNavigation
                  ? CustomBottomBar(
                      currentIndex: 4,
                      onTap: (index) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ResponsiveMainScreen(initialIndex: index),
                          ),
                        );
                      },
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  // ----------------------------------------------------------------- pieces

  Widget _header(AppPalette p, String nickname, String email, String cat,
      String? avatarUrl,
      {String? bio, String? city, int? age}) {
    final chips = <Widget>[];
    if (city != null && city.isNotEmpty) {
      chips.add(_infoChip(p, Icons.location_city_rounded, city));
    }
    if (age != null) {
      chips.add(_infoChip(p, Icons.cake_rounded, '$age'));
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: p.accent, width: 3),
            ),
            child: CircleAvatar(
              radius: 46,
              backgroundColor: p.accent.withValues(alpha: 0.35),
              backgroundImage: _avatar(cat, avatarUrl),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            nickname,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: p.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(fontSize: 14, color: p.textMuted),
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: chips,
            ),
          ],
          if (bio != null && bio.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              bio,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: p.text.withValues(alpha: 0.75),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(AppPalette p, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: p.accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: p.primary),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: p.text, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _settingsCard(AppPalette p, List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(children: rows),
    );
  }

  Widget _row(AppPalette p, IconData icon, String title, VoidCallback onTap,
      {String? trailing}) {
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
                  color: p.accent.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: p.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: p.text,
                  ),
                ),
              ),
              if (trailing != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    trailing,
                    style: TextStyle(fontSize: 13, color: p.textMuted),
                  ),
                ),
              Icon(Icons.chevron_right_rounded,
                  color: p.text.withValues(alpha: 0.35)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider(AppPalette p) => Divider(
        height: 1,
        thickness: 1,
        indent: 68,
        endIndent: 16,
        color: p.text.withValues(alpha: 0.08),
      );

  Widget _logoutButton(BuildContext context, AppPalette p) {
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
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
                    color: p.danger.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.logout_rounded, size: 20, color: p.danger),
                ),
                const SizedBox(width: 14),
                Text(
                  'Log out',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: p.danger,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _guestMode(BuildContext context, AppPalette p) {
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_circle_rounded, size: 88, color: p.primary),
              const SizedBox(height: 16),
              Text(
                'You are in Guest Mode',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: p.text),
              ),
              const SizedBox(height: 8),
              Text(
                'Log in to save your steps and profile.',
                style: TextStyle(fontSize: 14, color: p.textMuted),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.primary,
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
