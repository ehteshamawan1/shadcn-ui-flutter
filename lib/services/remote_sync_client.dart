import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Simple Supabase-backed client for pushing queued changes when online.
/// It no-ops if Supabase is not configured (URL/key empty).
class RemoteSyncClient {
  RemoteSyncClient() {
    try {
      _client = Supabase.instance.client;
      debugPrint('RemoteSyncClient: Forbundet til Supabase - synkronisering aktiv');
    } catch (e) {
      debugPrint('RemoteSyncClient: Supabase ikke konfigureret - sync kører offline only');
    }
  }

  SupabaseClient? _client;
  bool _schemaInitialized = false;

  bool get isConfigured => _client != null;

  /// Initialize schema by calling the setup_schema function in Supabase
  Future<bool> ensureSchemaExists() async {
    if (!isConfigured || _client == null || _schemaInitialized) {
      return _schemaInitialized;
    }

    try {
      // Call the setup_schema function that creates tables if they don't exist
      await _client!.rpc('setup_schema');
      _schemaInitialized = true;
      debugPrint('RemoteSyncClient: Schema initialiseret succesfuldt');
      return true;
    } catch (e) {
      debugPrint('RemoteSyncClient: Kunne ikke initialisere schema: $e');
      debugPrint('RemoteSyncClient: Kør setup_schema SQL i Supabase først');
      return false;
    }
  }

  Future<void> upsert(String table, Map<String, dynamic> payload) async {
    if (!isConfigured || _client == null) {
      throw Exception('Supabase ikke konfigureret');
    }
    try {
      await _client!.from(table).upsert(payload);
    } catch (e) {
      throw Exception('Supabase upsert fejl: $e');
    }
  }

  Future<void> delete(String table, String id) async {
    if (!isConfigured || _client == null) {
      throw Exception('Supabase ikke konfigureret');
    }
    try {
      await _client!.from(table).delete().eq('id', id);
    } catch (e) {
      throw Exception('Supabase delete fejl: $e');
    }
  }

  /// Fetch all records from a table
  Future<List<Map<String, dynamic>>> fetchAll(String table) async {
    if (!isConfigured || _client == null) {
      throw Exception('Supabase ikke konfigureret');
    }
    try {
      final response = await _client!.from(table).select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Supabase fetch fejl: $e');
    }
  }
}
