import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _index(String loc) {
    if (loc.startsWith('/records'))      return 1;
    if (loc.startsWith('/appointments')) return 2;
    if (loc.startsWith('/analytics'))   return 3;
    if (loc.startsWith('/assistant'))   return 4;
    if (loc.startsWith('/profile'))     return 5;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index(loc),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFe0f2fe),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/dashboard');
            case 1: context.go('/records');
            case 2: context.go('/appointments');
            case 3: context.go('/analytics');
            case 4: context.go('/assistant');
            case 5: context.go('/profile');
          }
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF0ea5e9)),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder_rounded, color: Color(0xFF0ea5e9)),
              label: 'Records'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded, color: Color(0xFF0ea5e9)),
              label: 'Calendar'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded, color: Color(0xFF0ea5e9)),
              label: 'Analytics'),
          NavigationDestination(
              icon: Icon(Icons.smart_toy_outlined),
              selectedIcon: Icon(Icons.smart_toy_rounded, color: Color(0xFF0ea5e9)),
              label: 'AI Chat'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF0ea5e9)),
              label: 'Profile'),
        ],
      ),
    );
  }
}
