import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../constants/roles_and_features.dart';
import 'database_service.dart';
import 'push_notification_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _db = DatabaseService();
  User? _currentUser;

  static const String _currentUserKey = 'current_user_id';

  // Get current logged in user
  User? get currentUser => _currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  // Login with PIN
  Future<bool> login(String pin) async {
    try {
      final users = _db.getAllUsers();
      final user = users.firstWhere(
        (u) => u.pin == pin,
        orElse: () => throw Exception('Invalid PIN'),
      );

      _currentUser = user;

      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, user.id);

      // Save FCM token for push notifications
      await _saveFcmToken(user);

      print('✅ User logged in: ${user.name} (${user.role})');
      return true;
    } catch (e) {
      print('❌ Login failed: $e');
      return false;
    }
  }

  // Save FCM token for push notifications
  Future<void> _saveFcmToken(User user) async {
    try {
      final pushService = PushNotificationService();
      final fcmToken = pushService.fcmToken;

      if (fcmToken != null && fcmToken != user.fcmToken) {
        user.fcmToken = fcmToken;
        await _db.updateUser(user);
        print('✅ FCM token saved for ${user.name}');
      }
    } catch (e) {
      print('❌ Failed to save FCM token: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);

    print('✅ User logged out');
  }

  // Restore session from shared preferences
  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_currentUserKey);

      if (userId != null) {
        final user = await _db.getUser(userId);
        if (user != null) {
          _currentUser = user;
          print('✅ Session restored: ${user.name}');
        }
      }
    } catch (e) {
      print('❌ Failed to restore session: $e');
    }
  }

  // Validate PIN format
  bool isValidPin(String pin) {
    return pin.length == 4 && int.tryParse(pin) != null;
  }

  // Get user role
  String? get userRole => _currentUser?.role;

  // Check if user is admin
  bool get isAdmin => _currentUser?.role == 'admin';

  // Check if user is tekniker
  bool get isTekniker => _currentUser?.role == 'tekniker';

  // Check if user is bogholder
  bool get isBogholder => _currentUser?.role == 'bogholder';

  /// Check if current user has a specific feature enabled
  bool hasFeature(String featureKey) {
    if (_currentUser == null) return false;

    // Admins have all features by default
    if (_currentUser!.role == AppRoles.admin) {
      return true;
    }

    // Check if feature is explicitly enabled for this user
    final enabledFeatures = _currentUser!.enabledFeatures ?? [];
    return enabledFeatures.contains(featureKey);
  }

  /// Check if current user can access a specific screen
  bool canAccessScreen(String screenKey) {
    if (_currentUser == null) return false;
    return hasFeature(screenKey);
  }

  /// Get all available features for the current user
  List<String> getAvailableFeatures() {
    if (_currentUser == null) return [];

    if (_currentUser!.role == AppRoles.admin) {
      return AppFeatures.all;
    }

    return _currentUser!.enabledFeatures ?? [];
  }
}
