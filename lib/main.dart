import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/dashboard/presentation/master_dashboard.dart';
import 'features/dashboard/presentation/school_detail_page.dart';
import 'features/dashboard/domain/school_model.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/feedback/presentation/feedback_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  // Note: Values should be passed from .env via --dart-define
  // flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  runApp(const ProviderScope(child: MyApp()));
}

final _routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const MasterDashboard(),
        routes: [
           GoRoute(
            path: 'school/:id',
            builder: (context, state) {
              final school = state.extra as School;
              return SchoolDetailPage(school: school);
            },
          ),
          GoRoute(
            path: 'feedback',
            builder: (context, state) => const FeedbackPage(),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = authState.value?.session != null;
      final isLoggingIn = state.uri.toString() == '/login';
      final isLoading = authState.isLoading;
      
      if (isLoading) return null;

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/dashboard';

      return null;
    },
    refreshListenable: AuthStateListenable(ref),
  );
});

class AuthStateListenable extends ChangeNotifier {
  AuthStateListenable(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    
    return MaterialApp.router(
      title: 'Prism Matrix Super Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A1A1A),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
