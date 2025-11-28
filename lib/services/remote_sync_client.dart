import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Callback type for real-time changes
typedef RealtimeChangeCallback = void Function(String table, String eventType, Map<String, dynamic> data);

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
  RealtimeChannel? _realtimeChannel;
  final List<RealtimeChangeCallback> _changeCallbacks = [];

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

  /// Add a callback for real-time changes
  void addChangeCallback(RealtimeChangeCallback callback) {
    _changeCallbacks.add(callback);
  }

  /// Remove a callback
  void removeChangeCallback(RealtimeChangeCallback callback) {
    _changeCallbacks.remove(callback);
  }

  /// Subscribe to real-time changes for all tables
  Future<void> subscribeToRealtimeChanges() async {
    if (!isConfigured || _client == null) {
      debugPrint('RemoteSyncClient: Kan ikke abonnere - Supabase ikke konfigureret');
      return;
    }

    // Unsubscribe from existing channel if any
    await unsubscribeFromRealtimeChanges();

    try {
      // Create a channel for all database changes
      _realtimeChannel = _client!.channel('db-changes');

      // Subscribe to all relevant tables
      final tables = [
        'users',
        'sager',
        'affugtere',
        'blokke',
        'blok_completions',
        'equipment_logs',
        'timer_logs',
        'kabel_slange_logs',
        'messages',
        'activity_logs',
      ];

      for (final table in tables) {
        _realtimeChannel!.onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          callback: (payload) {
            _handleRealtimeChange(table, payload);
          },
        );
      }

      // Subscribe to the channel
      _realtimeChannel!.subscribe((status, error) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          debugPrint('RemoteSyncClient: Real-time abonnement aktivt');
        } else if (status == RealtimeSubscribeStatus.closed) {
          debugPrint('RemoteSyncClient: Real-time abonnement lukket');
        } else if (error != null) {
          debugPrint('RemoteSyncClient: Real-time fejl: $error');
        }
      });

      debugPrint('RemoteSyncClient: Oprettet real-time abonnement for ${tables.length} tabeller');
    } catch (e) {
      debugPrint('RemoteSyncClient: Kunne ikke oprette real-time abonnement: $e');
    }
  }

  /// Handle incoming real-time changes
  void _handleRealtimeChange(String table, PostgresChangePayload payload) {
    final eventType = payload.eventType.name; // INSERT, UPDATE, DELETE
    final newData = payload.newRecord;
    final oldData = payload.oldRecord;

    debugPrint('RemoteSyncClient: Real-time ændring - $table/$eventType');

    // Use new data for INSERT/UPDATE, old data for DELETE
    final data = eventType == 'DELETE'
        ? Map<String, dynamic>.from(oldData)
        : Map<String, dynamic>.from(newData);

    // Notify all callbacks
    for (final callback in _changeCallbacks) {
      try {
        callback(table, eventType, data);
      } catch (e) {
        debugPrint('RemoteSyncClient: Callback fejl: $e');
      }
    }
  }

  /// Unsubscribe from real-time changes
  Future<void> unsubscribeFromRealtimeChanges() async {
    if (_realtimeChannel != null) {
      try {
        await _client?.removeChannel(_realtimeChannel!);
        _realtimeChannel = null;
        debugPrint('RemoteSyncClient: Real-time abonnement afmeldt');
      } catch (e) {
        debugPrint('RemoteSyncClient: Kunne ikke afmelde real-time: $e');
      }
    }
  }

  /// Dispose of resources
  void dispose() {
    unsubscribeFromRealtimeChanges();
    _changeCallbacks.clear();
  }
}
