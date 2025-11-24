import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:provider/provider.dart';
import 'package:pawquest/providers/step_provider.dart';
import 'package:pawquest/screens/main_screen.dart'; // 主界面
import 'package:pawquest/screens/splash_screen.dart'; // 启动页
import 'package:pawquest/screens/login_screen.dart'; // 登录页
import 'package:pawquest/init/init_cities_firestore.dart'; // 初始化城市数据
import 'package:pawquest/screens/world_map_screen.dart';
import 'package:pawquest/screens/foodsticker_screen.dart';
import 'package:pawquest/screens/app_theme.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 上传城市数据（仅首次运行）
  await uploadCitiesToFirestore();

  // 🔥 StepProvider 只初始化一次（关键）
  final stepProvider = StepProvider();
  await stepProvider.loadSavedSteps(); // 加载 Firestore / 本地步数
  stepProvider.startListening();       // 启动 pedometer（监听器）

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<StepProvider>.value(
          value: stepProvider, 
        ),
      ],
      child: const PawQuestApp(),
    ),
  );
}

class PawQuestApp extends StatelessWidget {
  const PawQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawQuest',
      debugShowCheckedModeBanner: false,
     theme: AppTheme.mainTheme,
      initialRoute: '/', // 设置初始路由
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(), // ✅ 登录页路由已注册
        '/main': (context) => const MainScreen(),   // ✅ 主界面路由（可选）
        '/map': (context) => const WorldMapScreen(), 
         '/badges': (context) => const FoodStickerScreen(), 
         
      },
    );
  }
}
