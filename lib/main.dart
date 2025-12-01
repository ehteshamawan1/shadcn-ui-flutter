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
  try {
    await DatabaseService().init();

    // Initialize sync service (queues offline changes and syncs when online)
    await SyncService().init();

    // Note: Session is NOT restored on startup - user must always login with PIN
    // await AuthService().restoreSession();

    runApp(const SkaDanApp());
  } catch (e) {
    debugPrint('Database initialization error: $e');
    runApp(DatabaseErrorApp(error: e.toString()));
  }
}

/// App widget shown when database initialization fails
class DatabaseErrorApp extends StatelessWidget {
  final String error;

  const DatabaseErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SKA-DAN - Fejl',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Database Fejl',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Der opstod en fejl under indlæsning af databasen.\n'
                  'Dette skyldes sandsynligvis forældet data i browseren.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Løsning:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('1. Åbn browser indstillinger (F12 → Application)'),
                      const Text('2. Find "IndexedDB" i venstre side'),
                      const Text('3. Slet alle "ska-dan" / "HiveDB" data'),
                      const Text('4. Genindlæs siden (Ctrl+F5)'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    'Fejl: $error',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
          final sagId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (_) => isLoggedIn
                ? TimerRegistreringScreen(sagId: sagId)
                : const LoginScreen(),
          );
        }

        if (settings.name != null && settings.name!.startsWith('/nfc-scanner/')) {
          final sagId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (_) => isLoggedIn
                ? NFCScannerScreen(sagId: sagId)
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
