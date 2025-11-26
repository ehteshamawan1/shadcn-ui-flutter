/// Supabase configuration
///
/// Values are loaded from compile-time environment variables to avoid
/// hardcoding keys in koden. Kør f.eks.:
/// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
