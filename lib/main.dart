import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/sager_screen.dart';
import 'screens/sag_detaljer_screen.dart';
import 'screens/ny_sag_screen.dart';
import 'screens/user_management_screen.dart';
import 'screens/nfc_scanner_screen.dart';
import 'screens/timer_registrering_screen.dart';
import 'screens/affugtere_screen.dart';
import 'screens/admin_settings_screen.dart';
import 'screens/role_permissions_screen.dart';
import 'screens/initial_setup_screen.dart';
import 'services/sync_service.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (primary storage)
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  } else {
    debugPrint('Supabase er ikke konfigureret (SUPABASE_URL/SUPABASE_ANON_KEY mangler). '
        'Appen kører offline only.');
  }

  // Initialize database service (which handles Hive initialization)
  await DatabaseService().init();

  // Initialize sync service (queues offline changes and syncs when online)
  await SyncService().init();

  // Note: Session is NOT restored on startup - user must always login with PIN
  // await AuthService().restoreSession();

  runApp(const SkaDanApp());
}

class SkaDanApp extends StatelessWidget {
  const SkaDanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'SKA-DAN',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            initialRoute: '/',
            onGenerateRoute: _generateRoute,
          );
        },
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    // Check authentication for protected routes
    final authService = AuthService();
    final dbService = DatabaseService();
    final isLoggedIn = authService.isLoggedIn;
    final hasUsers = dbService.getAllUsers().isNotEmpty;

    switch (settings.name) {
      case '/':
        if (!hasUsers) {
          return MaterialPageRoute(builder: (_) => const InitialSetupScreen());
        }
        return MaterialPageRoute(
          builder: (_) => isLoggedIn ? const DashboardScreen() : const LoginScreen(),
        );

      case '/login':
        if (!hasUsers) {
          return MaterialPageRoute(builder: (_) => const InitialSetupScreen());
        }
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );

      case '/dashboard':
        return MaterialPageRoute(
          builder: (_) => isLoggedIn ? const DashboardScreen() : const LoginScreen(),
        );

      case '/sager':
        return MaterialPageRoute(
          builder: (_) => isLoggedIn
              ? const SagerScreen()
              : const LoginScreen(),
        );

      case '/affugtere':
        return MaterialPageRoute(
          builder: (_) => isLoggedIn
              ? const AffugtereScreen()
              : const LoginScreen(),
        );

      case '/udstyr-oversigt':
        // Redirect to affugtere screen (now called Udstyr Oversigt)
        return MaterialPageRoute(
          builder: (_) => isLoggedIn
              ? const AffugtereScreen()
              : const LoginScreen(),
        );

      case '/nfc-scanner':
        return MaterialPageRoute(
          builder: (_) => isLoggedIn
              ? const NFCScannerScreen()
              : const LoginScreen(),
        );

      case '/timer':
        return MaterialPageRoute(
          builder: (_) => isLoggedIn
              ? const TimerRegistreringScreen()
              : const LoginScreen(),
        );

      case '/sager/ny':
        return MaterialPageRoute(
          builder: (_) => isLoggedIn
              ? const NySagScreen()
              : const LoginScreen(),
        );

      case '/users':
        return MaterialPageRoute(
          builder: (_) => isLoggedIn
              ? const UserManagementScreen()
              : const LoginScreen(),
        );

      case '/admin-settings':
        return MaterialPageRoute(
          builder: (_) => isLoggedIn && authService.currentUser?.role == 'admin'
              ? const AdminSettingsScreen()
              : const LoginScreen(),
        );

      case '/role-permissions':
        return MaterialPageRoute(
          builder: (_) => isLoggedIn && authService.currentUser?.role == 'admin'
              ? const RolePermissionsScreen()
              : const LoginScreen(),
        );

      case '/setup':
        return MaterialPageRoute(
          builder: (_) => const InitialSetupScreen(),
        );

      default:
        // Handle dynamic routes like /sager/:id
        if (settings.name != null && settings.name!.startsWith('/sager/')) {
          final sagId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (_) => isLoggedIn
                ? SagDetaljerScreen(sagId: sagId)
                : const LoginScreen(),
          );
        }

        if (settings.name != null && settings.name!.startsWith('/timer/')) {
          // final sagId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (_) => isLoggedIn
                ? const Placeholder() // TODO: Create TimerRegistreringScreen(sagId: sagId)
                : const LoginScreen(),
          );
        }

        if (settings.name != null && settings.name!.startsWith('/nfc-scanner/')) {
          // final sagId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (_) => isLoggedIn
                ? const Placeholder() // TODO: Create NFCScannerScreen(sagId: sagId)
                : const LoginScreen(),
          );
        }

        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('404 - Side ikke fundet'),
            ),
          ),
        );
    }
  }
}

// Loading screen widget
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authService = AuthService();
    await authService.restoreSession();

    if (mounted) {
      if (authService.isLoggedIn) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Indlæser...'),
          ],
        ),
      ),
    );
  }
}
