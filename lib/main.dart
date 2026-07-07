import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/records_screen.dart';
import 'screens/assistant_screen.dart';

void main() => runApp(const HealthCompassApp());

final _router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final loggedIn = await ApiService.isLoggedIn();
    if (!loggedIn && state.matchedLocation != '/login') return '/login';
    if (loggedIn  && state.matchedLocation == '/login') return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(path: '/login',     builder: (ctx, s) => const LoginScreen()),
    GoRoute(path: '/dashboard', builder: (ctx, s) => const DashboardScreen()),
    GoRoute(path: '/records',   builder: (ctx, s) => const RecordsScreen()),
    GoRoute(path: '/assistant', builder: (ctx, s) => const AssistantScreen()),
  ],
);

class HealthCompassApp extends StatelessWidget {
  const HealthCompassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HealthCompass',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0ea5e9),
        useMaterial3: true,
      ),
    );
  }
}
