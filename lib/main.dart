import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/api_service.dart';
import 'core/auth_state.dart';
import 'core/notification_service.dart';
import 'models/appointment.dart';
import 'models/user_profile.dart';
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
import 'screens/population_insights_screen.dart';
import 'screens/appointments_screen.dart';
import 'screens/create_appointment_screen.dart';
import 'screens/icu_screen.dart';
import 'screens/seizure_realtime_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    await NotificationService.init();
  }
  if (await ApiService.isLoggedIn()) authState.markLoggedIn();
  runApp(
    ChangeNotifierProvider.value(
      value: authState,
      child: const HealthCompassApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/login',
  refreshListenable: authState,
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
        GoRoute(path: '/dashboard',    builder: (c, s) => const DashboardScreen()),
        GoRoute(path: '/records',      builder: (c, s) => const RecordsScreen()),
        GoRoute(path: '/appointments', builder: (c, s) => const AppointmentsScreen()),
        GoRoute(path: '/analytics',    builder: (c, s) => const AnalyticsScreen()),
        GoRoute(path: '/assistant',    builder: (c, s) => const AssistantScreen()),
        GoRoute(path: '/profile',      builder: (c, s) => const ProfileScreen()),
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
    GoRoute(path: '/edit-profile',   builder: (c, s) => EditProfileScreen(user: s.extra as UserProfile)),
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
    GoRoute(path: '/seizure-analysis',    builder: (c, s) => const SeizureAnalysisScreen()),
    GoRoute(path: '/seizure-realtime',    builder: (c, s) => const SeizureRealtimeScreen()),
    GoRoute(path: '/icu',                 builder: (c, s) => const IcuScreen()),
    GoRoute(path: '/population-insights', builder: (c, s) => const PopulationInsightsScreen()),
    GoRoute(
      path: '/appointments/create',
      builder: (c, s) => const CreateAppointmentScreen(),
    ),
    GoRoute(
      path: '/appointments/:id/edit',
      builder: (c, s) => CreateAppointmentScreen(
        existing: s.extra as Appointment?,
      ),
    ),
  ],
);

// Web's brand indigo (matches the gradients already used throughout the
// screens, e.g. Color(0xFF6366f1)/Color(0xFF4338ca) in assistant_screen.dart).
const _brandSeed = Color(0xFF4F46E5);

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final colorScheme = ColorScheme.fromSeed(seedColor: _brandSeed, brightness: brightness);
  final base = ThemeData(colorScheme: colorScheme, useMaterial3: true, brightness: brightness);

  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme),
    scaffoldBackgroundColor: isDark ? const Color(0xFF0f172a) : const Color(0xFFf0f7ff),
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? const Color(0xFF1e293b) : Colors.white,
      foregroundColor: isDark ? Colors.white : const Color(0xFF1e293b),
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: isDark ? const Color(0xFF1e293b) : Colors.white,
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

class HealthCompassApp extends StatelessWidget {
  const HealthCompassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HealthCompass',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
    );
  }
}
