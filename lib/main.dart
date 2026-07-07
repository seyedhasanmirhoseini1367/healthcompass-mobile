import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/api_service.dart';
import 'widgets/app_shell.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/records_screen.dart';
import 'screens/record_detail_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/assistant_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/upload_record_screen.dart';
import 'screens/ai_models_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/emergency_card_screen.dart';
import 'screens/predictions_screen.dart';
import 'screens/prediction_detail_screen.dart';
import 'screens/run_model_screen.dart';
import 'screens/seizure_analysis_screen.dart';

void main() => runApp(const HealthCompassApp());

final _router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final loggedIn = await ApiService.isLoggedIn();
    final pub = ['/login', '/register', '/forgot-password'];
    if (!loggedIn && !pub.contains(state.matchedLocation)) return '/login';
    if (loggedIn  &&  pub.contains(state.matchedLocation)) return '/dashboard';
    return null;
  },
  routes: [
    // ── Public routes ──────────────────────────────────────────────────────
    GoRoute(path: '/login',           builder: (c, s) => const LoginScreen()),
    GoRoute(path: '/register',        builder: (c, s) => const RegisterScreen()),
    GoRoute(path: '/forgot-password', builder: (c, s) => const ForgotPasswordScreen()),

    // ── Authenticated shell (bottom nav) ───────────────────────────────────
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/dashboard', builder: (c, s) => const DashboardScreen()),
        GoRoute(path: '/records',   builder: (c, s) => const RecordsScreen()),
        GoRoute(path: '/analytics', builder: (c, s) => const AnalyticsScreen()),
        GoRoute(path: '/assistant', builder: (c, s) => const AssistantScreen()),
        GoRoute(path: '/profile',   builder: (c, s) => const ProfileScreen()),
      ],
    ),

    // ── Full-screen routes (no bottom nav) ─────────────────────────────────
    GoRoute(
      path: '/records/:id',
      builder: (c, s) => RecordDetailScreen(recordId: s.pathParameters['id']!),
    ),
    GoRoute(path: '/notifications',  builder: (c, s) => const NotificationsScreen()),
    GoRoute(path: '/upload',         builder: (c, s) => const UploadRecordScreen()),
    GoRoute(path: '/ai-models',      builder: (c, s) => const AIModelsScreen()),
    GoRoute(path: '/edit-profile',   builder: (c, s) => EditProfileScreen(user: s.extra as Map<String, dynamic>)),
    GoRoute(path: '/change-password', builder: (c, s) => const ChangePasswordScreen()),
    GoRoute(path: '/emergency-card', builder: (c, s) => const EmergencyCardScreen()),
    GoRoute(path: '/predictions',    builder: (c, s) => const PredictionsScreen()),
    GoRoute(
      path: '/predictions/:id',
      builder: (c, s) => PredictionDetailScreen(predictionId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/ai-models/:slug/run',
      builder: (c, s) => RunModelScreen(modelSlug: s.pathParameters['slug']!),
    ),
    GoRoute(path: '/seizure-analysis', builder: (c, s) => const SeizureAnalysisScreen()),
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
        fontFamily: 'Roboto',
      ),
    );
  }
}
