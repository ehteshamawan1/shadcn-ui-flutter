import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/push_notification_service.dart';
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

  // Initialize Firebase (for push notifications)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[Firebase] Initialized successfully');
  } catch (e) {
    debugPrint('[Firebase] Initialization error (non-fatal): $e');
  }

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

    // Initialize push notifications (after database is ready)
    try {
      await PushNotificationService().initialize();
    } catch (e) {
      debugPrint('[FCM] Initialization error (non-fatal): $e');
    }

    // Note: Session is NOT restored on startup - user must always login with PIN
    // await AuthService().restoreSession();

    runApp(const SkaDanApp());
  } catch (e) {
    debugPrint('Database initialization error: $e');
    final errorStr = e.toString();

    // If it's a Hive/TypeId error, show instructions to clear IndexedDB
    if (errorStr.contains('typeId') || errorStr.contains('HiveError') || errorStr.contains('adapter')) {
      runApp(DatabaseErrorApp(
        error: errorStr,
        showClearInstructions: true,
      ));
    } else {
      runApp(DatabaseErrorApp(error: errorStr));
    }
  }
}

/// App widget shown when database initialization fails
class DatabaseErrorApp extends StatefulWidget {
  final String error;
  final bool showClearInstructions;

  const DatabaseErrorApp({
    super.key,
    required this.error,
    this.showClearInstructions = false,
  });

  @override
  State<DatabaseErrorApp> createState() => _DatabaseErrorAppState();
}

class _DatabaseErrorAppState extends State<DatabaseErrorApp> {
  bool _isClearing = false;

  Future<void> _clearAndRetry() async {
    setState(() => _isClearing = true);

    try {
      // Try to delete all Hive boxes from disk
      await Hive.deleteFromDisk();
      debugPrint('Hive data cleared from disk');

      // Wait a moment for cleanup
      await Future.delayed(const Duration(milliseconds: 500));

      // Reload the page (web only)
      if (kIsWeb) {
        // ignore: avoid_web_libraries_in_flutter
        await Future.delayed(const Duration(milliseconds: 100));
        // Use JS interop to reload
        debugPrint('Reloading page...');
      }

      // Show success message before reload
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data ryddet! Genindlæser...'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // For web, we need to use window.location.reload()
      // Since we can't easily do that without dart:html, show instructions
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _isClearing = false);
    } catch (e) {
      debugPrint('Error clearing Hive: $e');
      setState(() => _isClearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SKA-DAN - Fejl',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(
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
                Text(
                  widget.showClearInstructions
                      ? 'Der opstod en fejl under indlæsning af databasen.\n'
                        'Dette skyldes forældet data i browseren fra en tidligere version.'
                      : 'Der opstod en fejl under indlæsning af databasen.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                if (widget.showClearInstructions) ...[
                  // Quick fix button
                  ElevatedButton.icon(
                    onPressed: _isClearing ? null : _clearAndRetry,
                    icon: _isClearing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_sweep),
                    label: Text(_isClearing ? 'Rydder data...' : 'Ryd data og prøv igen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'eller følg disse trin manuelt:',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manuel løsning:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text('1. Åbn browser indstillinger (F12 → Application)'),
                        Text('2. Find "IndexedDB" i venstre side'),
                        Text('3. Slet alle "ska-dan" / "HiveDB" data'),
                        Text('4. Genindlæs siden (Ctrl+F5)'),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(maxWidth: 500),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: SelectableText(
                    'Fejl: ${widget.error}',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Colors.red.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () {
                    // Trigger page reload via navigation
                    debugPrint('User requested reload');
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Genindlæs siden (Ctrl+F5)'),
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
