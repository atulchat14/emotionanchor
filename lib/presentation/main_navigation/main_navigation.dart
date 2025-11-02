import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../ai_insights_dashboard/ai_insights_dashboard.dart';
import '../journal_dashboard/journal_dashboard.dart';
import '../journal_writing_interface/journal_writing_interface.dart';
import '../settings_screen/settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1; // Start with Timeline (Journal Dashboard)

  final List<Widget> _screens = [
    const JournalWritingInterface(),
    const JournalDashboard(),
    const AIInsightsDashboard(),
    const SettingsScreen(),
  ];

  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.edit_outlined),
      activeIcon: Icon(Icons.edit),
      label: 'Write',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.format_list_bulleted_outlined),
      activeIcon: Icon(Icons.format_list_bulleted),
      label: 'Timeline',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.lightbulb_outline),
      activeIcon: Icon(Icons.lightbulb),
      label: 'Insights',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.settings_outlined),
      activeIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowLight,
              blurRadius: 8.0,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.surfaceLight,
          selectedItemColor: AppTheme.primaryLight,
          unselectedItemColor: AppTheme.textSecondaryLight,
          selectedLabelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.4,
          ),
          elevation: 0,
          items: _bottomNavItems,
        ),
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
