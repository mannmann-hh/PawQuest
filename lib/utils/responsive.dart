import 'package:flutter/material.dart';

class Responsive {
  static const double tabletBreakpoint = 600;

  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= tabletBreakpoint;
  }

  static bool isPhone(BuildContext context) {
    return !isTablet(context);
  }

  static bool isLandscape(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width > size.height;
  }
}
