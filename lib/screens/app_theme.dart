import 'package:flutter/material.dart';

class AppTheme {
  static const Color puddingBackground = Color(0xFFFFF7EC); // 奶白背景
  static const Color puddingYellow = Color(0xFFF8D66D);     // 主色黄
  static const Color puddingOrange = Color(0xFFF77F42);     // 暖橙 Logo
  static const Color puddingBrown = Color(0xFF6C4A2F);      // 主要文字
  static const Color mintGreen = Color.fromARGB(255, 31, 86, 106);         // 点缀小元素

  static final ThemeData mainTheme = ThemeData(
    fontFamily: "SF Pro Rounded", // 更可爱的字体，可换成你自己的
    scaffoldBackgroundColor: puddingBackground,

    colorScheme: ColorScheme.fromSeed(
      seedColor: puddingYellow,
      primary: puddingYellow,
      secondary: puddingOrange,
      surface: puddingBackground,
    ),

    // AppBar
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Color.fromRGBO(248, 214, 109, 1),
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: puddingBrown,
      ),
    ),

    // 按钮
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: puddingYellow,
        foregroundColor: puddingBrown,
        elevation: 3,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Card 圆角 + 阴影
cardTheme: CardThemeData(
  color: Colors.white,
  elevation: 4,
  shadowColor: Colors.black.withValues(alpha: 0.1),
  surfaceTintColor: Colors.transparent, // 禁用 M3 默认色调
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
  clipBehavior: Clip.antiAlias, // 推荐加上
),


    // 图标
    iconTheme: const IconThemeData(
      color: puddingBrown,
    ),

    // ListTile
    listTileTheme: const ListTileThemeData(
      iconColor: mintGreen,
      textColor: puddingBrown,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),

    // Text 文字
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: puddingBrown),
      bodyMedium: TextStyle(color: puddingBrown),
      titleLarge: TextStyle(
        color: puddingBrown,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
