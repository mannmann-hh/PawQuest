import 'package:flutter/material.dart';

import '../utils/responsive.dart';
import 'main_screen.dart';
import 'tablet/tablet_dashboard_screen.dart';

class ResponsiveMainScreen extends StatelessWidget {
  final int initialIndex;

  const ResponsiveMainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isTablet(context)) {
      return TabletDashboardScreen(initialIndex: initialIndex);
    }

    return MainScreen(initialIndex: initialIndex);
  }
}
