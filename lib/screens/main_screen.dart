import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '/firebase_options.dart';
import 'package:pawquest/screens/splash_screen.dart';
import 'package:pawquest/screens/home_screen.dart';
import 'package:pawquest/screens/foodsticker_screen.dart';
import 'package:pawquest/screens/community_screen.dart';
import 'package:pawquest/screens/user_screen.dart';
import '../widgets/custom_bottom_bar.dart';







void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PawQuestApp());
}

class PawQuestApp extends StatelessWidget {
  const PawQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF4EAB90),
          secondary: Color(0xFFEEBF6D),
          surface: Color(0xFFF6F6F6),
          onSurface: Colors.black87,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F6F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4EAB90),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: const SplashScreen(),
     
      
    );
  }
}

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  final List<Widget> _pages = [
    const HomeScreen(),
    const FoodStickerScreen(),
    CommunityScreen(), // 
    const UserScreen(),
    
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _pages.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Main Screen'), 
      // ),
      extendBody: true,
      body: _pages[_currentIndex],
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}



