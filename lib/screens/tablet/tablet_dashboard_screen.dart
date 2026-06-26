import 'package:flutter/material.dart';

import 'tablet_badge_page.dart';
import 'tablet_community_page.dart';
import 'tablet_overview_page.dart';
import 'tablet_profile_page.dart';
import 'tablet_weather_page.dart';

class TabletDashboardScreen extends StatefulWidget {
  final int initialIndex;

  const TabletDashboardScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<TabletDashboardScreen> createState() => _TabletDashboardScreenState();
}

class _TabletDashboardScreenState extends State<TabletDashboardScreen> {
  late int _selectedIndex;

  final List<Widget> _pages = const [
    TabletOverviewPage(),
    TabletBadgePage(),
    TabletWeatherPage(),
    TabletCommunityPage(),
    TabletProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, _pages.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EB),
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              minWidth: 86,
              groupAlignment: -0.8,
              backgroundColor: const Color(0xFFFFE8BC),
              selectedIconTheme: const IconThemeData(
                color: Color(0xFFF77F42),
                size: 30,
              ),
              unselectedIconTheme: const IconThemeData(
                color: Color(0xFF8A715B),
                size: 26,
              ),
              selectedLabelTextStyle: const TextStyle(
                color: Color(0xFF6C4A2F),
                fontWeight: FontWeight.w800,
              ),
              unselectedLabelTextStyle: const TextStyle(
                color: Color(0xFF8A715B),
              ),
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Overview'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.emoji_events_outlined),
                  selectedIcon: Icon(Icons.emoji_events),
                  label: Text('Badges'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.cloud_outlined),
                  selectedIcon: Icon(Icons.cloud),
                  label: Text('Weather'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.forum_outlined),
                  selectedIcon: Icon(Icons.forum),
                  label: Text('Talk'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text('Profile'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _pages[_selectedIndex],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
