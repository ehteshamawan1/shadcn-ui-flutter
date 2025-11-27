/// Supabase configuration
///
/// Default values are set for development. For production, override with
/// environment variables:
/// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class SupabaseConfig {
  // Default development values - can be overridden via --dart-define
  static const String _defaultUrl = 'https://hwjjwenymlgxbfwdtrbr.supabase.co';
  static const String _defaultAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh3amp3ZW55bWxneGJmd2R0cmJyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM2MTc4ODEsImV4cCI6MjA3OTE5Mzg4MX0.hlOBlhPbG1msAVZH1J9E-1x1B7FkccZYR3OmlRqV2io';

  // Use environment variable if provided, otherwise use default
  static const String _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get supabaseUrl => _envUrl.isNotEmpty ? _envUrl : _defaultUrl;
  static String get supabaseAnonKey => _envAnonKey.isNotEmpty ? _envAnonKey : _defaultAnonKey;

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
