import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/sync_task.dart';
import '../models/user.dart';
import '../models/sag.dart';
import '../models/affugter.dart';
import '../models/equipment_log.dart';
import '../models/timer_log.dart';
import '../models/blok.dart';
import '../models/blok_completion.dart';
import '../models/kabel_slange_log.dart';
import '../models/sag_message.dart';
import '../models/activity_log.dart';
import 'database_service.dart';
import 'remote_sync_client.dart';

/// Handles queuing of local changes and pushes them to the cloud once online.
/// Also subscribes to Supabase real-time changes for cross-device sync.
class SyncService {
  SyncService._internal();
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;

  final _uuid = const Uuid();
  final _remoteClient = RemoteSyncClient();

  Box<SyncTask>? _queueBox;
  StreamSubscription<dynamic>? _connectivitySub;
  bool _initialized = false;
  bool _isSyncing = false;
  bool _initialSyncComplete = false;
  bool _realtimeSubscribed = false;

  // Callbacks for notifying UI of real-time changes
  final List<void Function(String entityType, String action, Map<String, dynamic> data)> _realtimeListeners = [];

  Future<void> init() async {
    if (_initialized) return;

    _queueBox = Hive.box<SyncTask>(DatabaseService.syncQueueBox);
    _initialized = true;

    // Setup real-time change handler
    _remoteClient.addChangeCallback(_handleRealtimeChange);

    // Lyt på connectivity og sync når vi kommer online
    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      (status) async {
        if (_isOnline(status)) {
          await syncPending();
          // Subscribe to real-time when online
          if (!_realtimeSubscribed) {
            await _subscribeToRealtime();
          }
        }
      },
    );

    // Prøv initial sync ved start hvis vi allerede er online
    final status = await Connectivity().checkConnectivity();
    if (_isOnline(status)) {
      await pullFromRemote(); // hent først
      await syncPending(); // skub derefter
      await _subscribeToRealtime(); // start real-time
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
    _remoteClient.removeChangeCallback(_handleRealtimeChange);
    _remoteClient.dispose();
    _realtimeListeners.clear();
  }

  bool get hasPending => (_queueBox?.isNotEmpty ?? false);
  bool get isInitialSyncComplete => _initialSyncComplete;
  bool get isRealtimeActive => _realtimeSubscribed;

  /// Get count of pending changes
  int get pendingChangesCount => _queueBox?.length ?? 0;

  /// Add a listener for real-time changes from other devices
  void addRealtimeListener(void Function(String entityType, String action, Map<String, dynamic> data) listener) {
    _realtimeListeners.add(listener);
  }

  /// Remove a real-time listener
  void removeRealtimeListener(void Function(String entityType, String action, Map<String, dynamic> data) listener) {
    _realtimeListeners.remove(listener);
  }

  /// Subscribe to Supabase real-time changes
  Future<void> _subscribeToRealtime() async {
    if (_realtimeSubscribed) return;

    await _remoteClient.subscribeToRealtimeChanges();
    _realtimeSubscribed = true;
    debugPrint('[SYNC] Real-time abonnement startet');
  }

  /// Handle real-time changes from Supabase
  void _handleRealtimeChange(String table, String eventType, Map<String, dynamic> data) {
    debugPrint('[SYNC] Real-time ændring modtaget: $table/$eventType');

    // Convert table name to entity type
    final entityType = _entityTypeFor(table);

    // Update local Hive database
    _updateLocalFromRealtime(table, eventType, data);

    // Notify listeners (for UI updates)
    final action = eventType.toLowerCase();
    for (final listener in _realtimeListeners) {
      try {
        listener(entityType, action, data);
      } catch (e) {
        debugPrint('[SYNC] Listener fejl: $e');
      }
    }
  }

  /// Update local Hive database from real-time change
  Future<void> _updateLocalFromRealtime(String table, String eventType, Map<String, dynamic> data) async {
    try {
      switch (table) {
        case 'users':
          final box = Hive.box<User>(DatabaseService.usersBox);
          if (eventType == 'DELETE') {
            await box.delete(data['id']);
          } else {
            final user = User.fromJson(data);
            await box.put(user.id, user);
          }
          break;

        case 'sager':
          final box = Hive.box<Sag>(DatabaseService.sagerBox);
          if (eventType == 'DELETE') {
            await box.delete(data['id']);
          } else {
            final sag = Sag.fromJson(data);
            await box.put(sag.id, sag);
          }
          break;

        case 'affugtere':
          final box = Hive.box<Affugter>(DatabaseService.affugtereBox);
          if (eventType == 'DELETE') {
            await box.delete(data['id']);
          } else {
            final affugter = Affugter.fromJson(data);
            await box.put(affugter.id, affugter);
          }
          break;

        case 'blokke':
          final box = Hive.box<Blok>(DatabaseService.blokkeBox);
          if (eventType == 'DELETE') {
            await box.delete(data['id']);
          } else {
            final blok = Blok.fromJson(data);
            await box.put(blok.id, blok);
          }
          break;

        case 'blok_completions':
          final box = Hive.box<BlokCompletion>(DatabaseService.blokCompletionsBox);
          if (eventType == 'DELETE') {
            await box.delete(data['id']);
          } else {
            final completion = BlokCompletion.fromJson(data);
            await box.put(completion.id, completion);
          }
          break;

        case 'equipment_logs':
          final box = Hive.box<EquipmentLog>(DatabaseService.equipmentLogsBox);
          if (eventType == 'DELETE') {
            await box.delete(data['id']);
          } else {
            final log = EquipmentLog.fromJson(data);
            await box.put(log.id, log);
          }
          break;

        case 'timer_logs':
          final box = Hive.box<TimerLog>(DatabaseService.timerLogsBox);
          if (eventType == 'DELETE') {
            await box.delete(data['id']);
          } else {
            final log = TimerLog.fromJson(data);
            await box.put(log.id, log);
          }
          break;

        case 'kabel_slange_logs':
          final box = Hive.box<KabelSlangeLog>(DatabaseService.kabelSlangeLogsBox);
          if (eventType == 'DELETE') {
            await box.delete(data['id']);
          } else {
            final log = KabelSlangeLog.fromJson(data);
            await box.put(log.id, log);
          }
          break;

        case 'messages':
          final box = Hive.box<SagMessage>(DatabaseService.messagesBox);
          if (eventType == 'DELETE') {
            await box.delete(data['id']);
          } else {
            final msg = SagMessage.fromJson(data);
            await box.put(msg.id, msg);
          }
          break;

        case 'activity_logs':
          final box = Hive.box<ActivityLog>(DatabaseService.activityLogsBox);
          if (eventType == 'DELETE') {
            await box.delete(data['id']);
          } else {
            final log = ActivityLog.fromJson(data);
            await box.put(log.id, log);
          }
          break;
      }
      debugPrint('[SYNC] Lokal database opdateret fra real-time: $table/$eventType');
    } catch (e) {
      debugPrint('[SYNC] Fejl ved opdatering af lokal database: $e');
    }
  }

  String _entityTypeFor(String table) {
    switch (table) {
      case 'users': return 'user';
      case 'sager': return 'sag';
      case 'affugtere': return 'affugter';
      case 'equipment_logs': return 'equipment';
      case 'timer_logs': return 'timer';
      case 'blokke': return 'blok';
      case 'blok_completions': return 'blok_completion';
      case 'kabel_slange_logs': return 'kabel';
      case 'messages': return 'besked';
      case 'activity_logs': return 'activity';
      default: return table;
    }
  }

  /// Add a change to the queue. Data is stored locally and retried until success.
  Future<void> queueChange({
    required String entityType,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    if (!_initialized) {
      await init();
    }
    final task = SyncTask(
      id: _uuid.v4(),
      entityType: entityType,
      operation: operation,
      payload: payload,
      createdAt: DateTime.now().toIso8601String(),
    );
    await _queueBox?.put(task.id, task);
    debugPrint('Queued change (${task.entityType}/${task.operation})');

    // Prøv at synkronisere med det samme hvis vi er online
    await _triggerImmediateSyncIfOnline();
  }

  /// Pull data from Supabase and populate local database (Supabase er primær kilde)
  Future<void> pullFromRemote() async {
    if (!_initialized) {
      await init();
    }
    if (!_remoteClient.isConfigured) {
      debugPrint('Pull: Supabase ikke konfigureret');
      return;
    }

    try {
      debugPrint('[SYNC] Starter initial sync fra Supabase...');

      // NB: skriver direkte til Hive for at undgå nye queueChange-events

      try {
        final usersData = await _remoteClient.fetchAll('users');
        final box = Hive.box<User>(DatabaseService.usersBox);
        for (final data in usersData) {
          final user = User.fromJson(data);
          await box.put(user.id, user);
        }
        debugPrint('[SYNC] OK - Synkroniseret ${usersData.length} brugere');
      } catch (e) {
        debugPrint('[SYNC] FEJL - Kunne ikke hente brugere: $e');
      }

      try {
        final sagerData = await _remoteClient.fetchAll('sager');
        final box = Hive.box<Sag>(DatabaseService.sagerBox);
        for (final data in sagerData) {
          final sag = Sag.fromJson(data);
          await box.put(sag.id, sag);
        }
        debugPrint('[SYNC] OK - Synkroniseret ${sagerData.length} sager');
      } catch (e) {
        debugPrint('[SYNC] FEJL - Kunne ikke hente sager: $e');
      }

      try {
        final affugtereData = await _remoteClient.fetchAll('affugtere');
        final box = Hive.box<Affugter>(DatabaseService.affugtereBox);
        for (final data in affugtereData) {
          final affugter = Affugter.fromJson(data);
          await box.put(affugter.id, affugter);
        }
        debugPrint('[SYNC] OK - Synkroniseret ${affugtereData.length} affugtere');
      } catch (e) {
        debugPrint('[SYNC] FEJL - Kunne ikke hente affugtere: $e');
      }

      try {
        final blokkeData = await _remoteClient.fetchAll('blokke');
        final box = Hive.box<Blok>(DatabaseService.blokkeBox);
        for (final data in blokkeData) {
          final blok = Blok.fromJson(data);
          await box.put(blok.id, blok);
        }
        debugPrint('[SYNC] OK - Synkroniseret ${blokkeData.length} blokke');
      } catch (e) {
        debugPrint('[SYNC] FEJL - Kunne ikke hente blokke: $e');
      }

      try {
        final completionData = await _remoteClient.fetchAll('blok_completions');
        final box = Hive.box<BlokCompletion>(DatabaseService.blokCompletionsBox);
        for (final data in completionData) {
          final completion = BlokCompletion.fromJson(data);
          await box.put(completion.id, completion);
        }
        debugPrint('[SYNC] OK - Synkroniseret ${completionData.length} blok completions');
      } catch (e) {
        debugPrint('[SYNC] FEJL - Kunne ikke hente blok completions: $e');
      }

      try {
        final equipmentData = await _remoteClient.fetchAll('equipment_logs');
        final box = Hive.box<EquipmentLog>(DatabaseService.equipmentLogsBox);
        for (final data in equipmentData) {
          final log = EquipmentLog.fromJson(data);
          await box.put(log.id, log);
        }
        debugPrint('[SYNC] OK - Synkroniseret ${equipmentData.length} equipment logs');
      } catch (e) {
        debugPrint('[SYNC] FEJL - Kunne ikke hente equipment logs: $e');
      }

      try {
        final timerData = await _remoteClient.fetchAll('timer_logs');
        final box = Hive.box<TimerLog>(DatabaseService.timerLogsBox);
        for (final data in timerData) {
          final log = TimerLog.fromJson(data);
          await box.put(log.id, log);
        }
        debugPrint('[SYNC] OK - Synkroniseret ${timerData.length} timer logs');
      } catch (e) {
        debugPrint('[SYNC] FEJL - Kunne ikke hente timer logs: $e');
      }

      try {
        final kabelData = await _remoteClient.fetchAll('kabel_slange_logs');
        final box = Hive.box<KabelSlangeLog>(DatabaseService.kabelSlangeLogsBox);
        for (final data in kabelData) {
          final log = KabelSlangeLog.fromJson(data);
          await box.put(log.id, log);
        }
        debugPrint('[SYNC] OK - Synkroniseret ${kabelData.length} kabel/slange logs');
      } catch (e) {
        debugPrint('[SYNC] FEJL - Kunne ikke hente kabel/slange logs: $e');
      }

      try {
        final messageData = await _remoteClient.fetchAll('messages');
        final box = Hive.box<SagMessage>(DatabaseService.messagesBox);
        for (final data in messageData) {
          final msg = SagMessage.fromJson(data);
          await box.put(msg.id, msg);
        }
        debugPrint('[SYNC] OK - Synkroniseret ${messageData.length} beskeder');
      } catch (e) {
        debugPrint('[SYNC] FEJL - Kunne ikke hente beskeder: $e');
      }

      try {
        final activityData = await _remoteClient.fetchAll('activity_logs');
        final box = Hive.box<ActivityLog>(DatabaseService.activityLogsBox);
        for (final data in activityData) {
          final log = ActivityLog.fromJson(data);
          await box.put(log.id, log);
        }
        debugPrint('[SYNC] OK - Synkroniseret ${activityData.length} aktivitetslogs');
      } catch (e) {
        debugPrint('[SYNC] FEJL - Kunne ikke hente aktivitetslogs: $e');
      }

      _initialSyncComplete = true;
      debugPrint('[SYNC] OK - Initial sync gennemfoert');
    } catch (e) {
      debugPrint('[SYNC] FEJL - Initial sync fejlede: $e');
    }
  }

  Future<void> _triggerImmediateSyncIfOnline() async {
    if (!_initialized) {
      await init();
    }
    if (!_remoteClient.isConfigured) return;

    final status = await Connectivity().checkConnectivity();
    if (_isOnline(status)) {
      await syncPending();
    }
  }

  Future<void> syncPending() async {
    if (!_initialized) {
      await init();
    }
    if (_isSyncing || _queueBox == null || _queueBox!.isEmpty) return;
    if (!_remoteClient.isConfigured) {
      debugPrint('Sync pending, men Supabase er ikke konfigureret (SUPABASE_URL/SUPABASE_ANON_KEY)');
      return;
    }

    // Ensure schema exists before syncing
    await _remoteClient.ensureSchemaExists();

    _isSyncing = true;
    final tasks = List<SyncTask>.from(_queueBox!.values);

    for (final task in tasks) {
      final success = await _pushTask(task);
      if (success) {
        await _queueBox!.delete(task.id);
      } else {
        final updated = SyncTask(
          id: task.id,
          entityType: task.entityType,
          operation: task.operation,
          payload: task.payload,
          createdAt: task.createdAt,
          lastTriedAt: DateTime.now().toIso8601String(),
          attempts: task.attempts + 1,
        );
        await _queueBox!.put(task.id, updated);
      }
    }

    _isSyncing = false;
  }

  Future<bool> _pushTask(SyncTask task) async {
    try {
      final table = _tableFor(task.entityType);
      if (task.operation == 'delete') {
        final id = task.payload['id'] as String?;
        if (id == null || id.isEmpty) {
          throw Exception('Manglende id for delete-operation');
        }
        await _remoteClient.delete(table, id);
      } else {
        await _remoteClient.upsert(table, task.payload);
      }
      return true;
    } catch (e) {
      debugPrint('Sync failed for ${task.entityType}/${task.operation}: $e');
      return false;
    }
  }

  bool _isOnline(dynamic result) {
    // connectivity_plus >= 5 returnerer liste på nogle platforme
    if (result is List<ConnectivityResult>) {
      return result.any((r) => r != ConnectivityResult.none);
    }
    if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }
    return false;
  }

  String _tableFor(String entityType) {
    switch (entityType) {
      case 'user':
        return 'users';
      case 'sag':
        return 'sager';
      case 'affugter':
        return 'affugtere';
      case 'equipment_log':
        return 'equipment_logs';
      case 'timer_log':
        return 'timer_logs';
      case 'blok':
        return 'blokke';
      case 'blok_completion':
        return 'blok_completions';
      case 'kabel_slange_log':
        return 'kabel_slange_logs';
      case 'message':
        return 'messages';
      case 'activity_log':
        return 'activity_logs';
      default:
        return entityType;
    }
  }
}
