import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../models/sag.dart';
import '../models/affugter.dart';
import '../models/equipment_log.dart';
import '../models/timer_log.dart';
import '../models/blok.dart';
import '../models/blok_completion.dart';
import '../models/kabel_slange_log.dart';
import '../models/sync_task.dart';
import '../models/sag_message.dart';
import '../models/activity_log.dart';
import '../models/app_setting.dart';
import 'sync_service.dart';
import 'settings_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String usersBox = 'users';
  static const String sagerBox = 'sager';
  static const String affugtereBox = 'affugtere';
  static const String equipmentLogsBox = 'equipment_logs';
  static const String timerLogsBox = 'timer_logs';
  static const String blokkeBox = 'blokke';
  static const String blokCompletionsBox = 'blok_completions';
  static const String kabelSlangeLogsBox = 'kabel_slange_logs';
  static const String equipmentRegistryBox = 'equipment_registry';
  static const String pricingConfigsBox = 'pricing_configs';
  static const String kostpriserBox = 'kostpriser';
  static const String faktureringBox = 'fakturering';
  static const String syncQueueBox = 'sync_queue';
  static const String messagesBox = 'messages';
  static const String activityLogsBox = 'activity_logs';
  static const String appSettingsBox = 'app_settings';

  final _uuid = const Uuid();
  final SyncService _syncService = SyncService();

  Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters (guard against duplicate registration for hot restarts)
    // TypeIds: 0-11 are registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SagAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AffugterAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(EquipmentLogAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(TimerLogAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(BlokAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(BlokCompletionAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(SyncTaskAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(KabelSlangeLogAdapter());
    }
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(SagMessageAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(ActivityLogAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(AppSettingAdapter());
    }

    // Try to open boxes, with automatic recovery from corrupted data
    await _openBoxesWithRecovery();

    // Initialize sample data if needed
    await initSampleData();

    // Initialize settings service
    await SettingsService().init();
  }

  /// Open all Hive boxes with automatic recovery from corrupted/incompatible data
  Future<void> _openBoxesWithRecovery() async {
    try {
      await _openAllBoxes();
    } catch (e) {
      final errorStr = e.toString();
      // Handle corrupted data, unknown typeId, or other Hive errors
      if (errorStr.contains('unknown typeId') ||
          errorStr.contains('HiveError') ||
          errorStr.contains('type') ||
          errorStr.contains('adapter')) {
        debugPrint('=== HIVE DATABASE RECOVERY ===');
        debugPrint('Error detected: $errorStr');
        debugPrint('Clearing all boxes and recreating database...');

        // Clear all boxes from disk
        await _clearAllBoxes();

        // Wait a bit for cleanup to complete
        await Future.delayed(const Duration(milliseconds: 100));

        // Retry opening boxes
        try {
          await _openAllBoxes();
          debugPrint('Database recovery successful!');
        } catch (retryError) {
          debugPrint('Database recovery failed: $retryError');
          debugPrint('User should clear browser data (IndexedDB) manually');
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  /// Open all Hive boxes
  Future<void> _openAllBoxes() async {
    await Hive.openBox<User>(usersBox);
    await Hive.openBox<Sag>(sagerBox);
    await Hive.openBox<Affugter>(affugtereBox);
    await Hive.openBox<EquipmentLog>(equipmentLogsBox);
    await Hive.openBox<TimerLog>(timerLogsBox);
    await Hive.openBox<Blok>(blokkeBox);
    await Hive.openBox<BlokCompletion>(blokCompletionsBox);
    await Hive.openBox<KabelSlangeLog>(kabelSlangeLogsBox);
    await Hive.openBox(equipmentRegistryBox);
    await Hive.openBox(pricingConfigsBox);
    await Hive.openBox(kostpriserBox);
    await Hive.openBox(faktureringBox);
    await Hive.openBox<SyncTask>(syncQueueBox);
    await Hive.openBox<SagMessage>(messagesBox);
    await Hive.openBox<ActivityLog>(activityLogsBox);
    await Hive.openBox<AppSetting>(appSettingsBox);
  }

  Future<void> _clearAllBoxes() async {
    try {
      await Hive.deleteBoxFromDisk(usersBox);
      await Hive.deleteBoxFromDisk(sagerBox);
      await Hive.deleteBoxFromDisk(affugtereBox);
      await Hive.deleteBoxFromDisk(equipmentLogsBox);
      await Hive.deleteBoxFromDisk(timerLogsBox);
      await Hive.deleteBoxFromDisk(blokkeBox);
      await Hive.deleteBoxFromDisk(blokCompletionsBox);
      await Hive.deleteBoxFromDisk(kabelSlangeLogsBox);
      await Hive.deleteBoxFromDisk(equipmentRegistryBox);
      await Hive.deleteBoxFromDisk(pricingConfigsBox);
      await Hive.deleteBoxFromDisk(kostpriserBox);
      await Hive.deleteBoxFromDisk(faktureringBox);
      await Hive.deleteBoxFromDisk(syncQueueBox);
      await Hive.deleteBoxFromDisk(messagesBox);
      await Hive.deleteBoxFromDisk(activityLogsBox);
      await Hive.deleteBoxFromDisk(appSettingsBox);
      debugPrint('All Hive boxes cleared successfully');
    } catch (e) {
      debugPrint('Error clearing boxes: $e');
    }
  }

  // Users
  Box<User> get _usersBox => Hive.box<User>(usersBox);

  Future<void> addUser(User user, {String? byUserName}) async {
    await _usersBox.put(user.id, user);
    await _syncService.queueChange(
      entityType: 'user',
      operation: 'upsert',
      payload: user.toJson(),
    );
    await logActivity(
      entityType: 'user',
      action: 'create',
      entityId: user.id,
      description: 'Ny bruger oprettet: ${user.name}',
      newData: user.toJson(),
      userName: byUserName,
    );
  }

  Future<void> updateUser(User user, {String? byUserName}) async {
    final oldUser = _usersBox.get(user.id);
    await _usersBox.put(user.id, user);
    await _syncService.queueChange(
      entityType: 'user',
      operation: 'upsert',
      payload: user.toJson(),
    );
    await logActivity(
      entityType: 'user',
      action: 'update',
      entityId: user.id,
      description: 'Bruger opdateret: ${user.name}',
      oldData: oldUser?.toJson(),
      newData: user.toJson(),
      userName: byUserName,
    );
  }

  Future<User?> getUser(String id) async {
    return _usersBox.get(id);
  }

  List<User> getAllUsers() {
    return _usersBox.values.toList();
  }

  Future<void> deleteUser(String id, {String? byUserName}) async {
    final oldUser = _usersBox.get(id);
    await _usersBox.delete(id);
    await _syncService.queueChange(
      entityType: 'user',
      operation: 'delete',
      payload: {'id': id},
    );
    await logActivity(
      entityType: 'user',
      action: 'delete',
      entityId: id,
      description: 'Bruger slettet: ${oldUser?.name ?? id}',
      oldData: oldUser?.toJson(),
      userName: byUserName,
    );
  }

  // Sager
  Box<Sag> get _sagerBox => Hive.box<Sag>(sagerBox);

  Future<void> addSag(Sag sag) async {
    await _sagerBox.put(sag.id, sag);
    await _syncService.queueChange(
      entityType: 'sag',
      operation: 'upsert',
      payload: sag.toJson(),
    );
    await _logActivity(
      sagId: sag.id,
      type: 'sag',
      action: 'create',
      description: 'Ny sag oprettet: ${sag.sagsnr}',
      user: sag.oprettetAf,
    );
  }

  Future<Sag?> getSag(String id) async {
    return _sagerBox.get(id);
  }

  List<Sag> getAllSager() {
    return _sagerBox.values.toList();
  }

  Future<void> updateSag(Sag sag) async {
    await _sagerBox.put(sag.id, sag);
    await _syncService.queueChange(
      entityType: 'sag',
      operation: 'upsert',
      payload: sag.toJson(),
    );
    await _logActivity(
      sagId: sag.id,
      type: 'sag',
      action: 'update',
      description: 'Sag opdateret: ${sag.sagsnr}',
    );
  }

  Future<void> deleteSag(String id) async {
    final existing = _sagerBox.get(id);
    await _sagerBox.delete(id);
    await _syncService.queueChange(
      entityType: 'sag',
      operation: 'delete',
      payload: {'id': id},
    );
    await _logActivity(
      sagId: id,
      type: 'sag',
      action: 'delete',
      description: 'Sag slettet: ${existing?.sagsnr ?? id}',
    );
  }

  // Affugtere
  Box<Affugter> get _affugtereBox => Hive.box<Affugter>(affugtereBox);

  Future<void> addAffugter(Affugter affugter, {String? byUserName}) async {
    await _affugtereBox.put(affugter.id, affugter);
    await _syncService.queueChange(
      entityType: 'affugter',
      operation: 'upsert',
      payload: affugter.toJson(),
    );
    await logActivity(
      entityType: 'affugter',
      action: 'create',
      entityId: affugter.id,
      description: 'Ny affugter oprettet: ${affugter.nr} (${affugter.maerke ?? ''} ${affugter.model ?? ''})',
      newData: affugter.toJson(),
      userName: byUserName,
    );
  }

  Future<Affugter?> getAffugter(String id) async {
    return _affugtereBox.get(id);
  }

  Affugter? getAffugterByNr(String nr) {
    return _affugtereBox.values.firstWhere(
      (a) => a.nr == nr,
      orElse: () => throw Exception('Affugter not found'),
    );
  }

  List<Affugter> getAllAffugtere() {
    return _affugtereBox.values.toList();
  }

  Future<void> updateAffugter(Affugter affugter, {String? byUserName, String? sagId}) async {
    final oldAffugter = _affugtereBox.get(affugter.id);
    await _affugtereBox.put(affugter.id, affugter);
    await _syncService.queueChange(
      entityType: 'affugter',
      operation: 'upsert',
      payload: affugter.toJson(),
    );

    // Determine action and description based on what changed
    String action = 'update';
    String description = 'Affugter opdateret: ${affugter.nr}';

    if (oldAffugter != null) {
      // Check if status changed
      if (oldAffugter.status != affugter.status) {
        description = 'Affugter ${affugter.nr} status ændret: ${oldAffugter.status} -> ${affugter.status}';
      }
      // Check if assigned to a sag
      if (oldAffugter.currentSagId != affugter.currentSagId) {
        if (affugter.currentSagId != null && affugter.currentSagId!.isNotEmpty) {
          action = 'assign';
          description = 'Affugter ${affugter.nr} tildelt til sag';
        } else {
          action = 'unassign';
          description = 'Affugter ${affugter.nr} fjernet fra sag';
        }
      }
    }

    await logActivity(
      entityType: 'affugter',
      action: action,
      entityId: affugter.id,
      sagId: sagId ?? affugter.currentSagId,
      description: description,
      oldData: oldAffugter?.toJson(),
      newData: affugter.toJson(),
      userName: byUserName,
    );
  }

  Future<void> deleteAffugter(String id, {String? byUserName}) async {
    final oldAffugter = _affugtereBox.get(id);
    await _affugtereBox.delete(id);
    await _syncService.queueChange(
      entityType: 'affugter',
      operation: 'delete',
      payload: {'id': id},
    );
    await logActivity(
      entityType: 'affugter',
      action: 'delete',
      entityId: id,
      description: 'Affugter slettet: ${oldAffugter?.nr ?? id}',
      oldData: oldAffugter?.toJson(),
      userName: byUserName,
    );
  }

  // Equipment Logs
  Box<EquipmentLog> get _equipmentLogsBox =>
      Hive.box<EquipmentLog>(equipmentLogsBox);

  Future<void> addEquipmentLog(EquipmentLog log) async {
    await _equipmentLogsBox.put(log.id, log);
    await _syncService.queueChange(
      entityType: 'equipment_log',
      operation: 'upsert',
      payload: log.toJson(),
    );
    await _logActivity(
      sagId: log.sagId,
      type: 'equipment',
      action: 'create',
      description: '${log.category} ${log.action} (antal ${log.data['count'] ?? 1})',
      user: log.user,
    );
  }

  List<EquipmentLog> getEquipmentLogsBySag(String sagId) {
    return _equipmentLogsBox.values.where((log) => log.sagId == sagId).toList();
  }

  List<EquipmentLog> getAllEquipmentLogs() {
    return _equipmentLogsBox.values.toList();
  }

  // Timer Logs
  Box<TimerLog> get _timerLogsBox => Hive.box<TimerLog>(timerLogsBox);

  Future<void> addTimerLog(TimerLog log) async {
    await _timerLogsBox.put(log.id, log);
    await _syncService.queueChange(
      entityType: 'timer_log',
      operation: 'upsert',
      payload: log.toJson(),
    );
    await _logActivity(
      sagId: log.sagId,
      type: 'timer',
      action: 'create',
      description: '${log.type} - ${log.hours} t',
      user: log.user,
    );
  }

  List<TimerLog> getTimerLogsBySag(String sagId) {
    return _timerLogsBox.values.where((log) => log.sagId == sagId).toList();
  }

  List<TimerLog> getAllTimerLogs() {
    return _timerLogsBox.values.toList();
  }

  // Blokke
  Box<Blok> get _blokkeBox => Hive.box<Blok>(blokkeBox);

  Future<void> addBlok(Blok blok) async {
    await _blokkeBox.put(blok.id, blok);
    await _syncService.queueChange(
      entityType: 'blok',
      operation: 'upsert',
      payload: blok.toJson(),
    );
    await _logActivity(
      sagId: blok.sagId,
      type: 'blok',
      action: 'create',
      description: 'Blok oprettet: ${blok.navn}',
    );
  }

  Future<void> updateBlok(Blok blok) async {
    await _blokkeBox.put(blok.id, blok);
    await _syncService.queueChange(
      entityType: 'blok',
      operation: 'upsert',
      payload: blok.toJson(),
    );
    await _logActivity(
      sagId: blok.sagId,
      type: 'blok',
      action: 'update',
      description: 'Blok opdateret: ${blok.navn}',
    );
  }

  Future<void> deleteBlok(String id) async {
    final existing = _blokkeBox.get(id);
    await _blokkeBox.delete(id);
    await _syncService.queueChange(
      entityType: 'blok',
      operation: 'delete',
      payload: {'id': id},
    );
    await _logActivity(
      sagId: existing?.sagId ?? '',
      type: 'blok',
      action: 'delete',
      description: 'Blok slettet: ${existing?.navn ?? id}',
    );
  }

  List<Blok> getBlokkeBySag(String sagId) {
    return _blokkeBox.values.where((blok) => blok.sagId == sagId).toList()
      ..sort((a, b) => a.navn.compareTo(b.navn));
  }

  List<Blok> getAllBlokke() {
    return _blokkeBox.values.toList();
  }

  // Blok Completions
  Box<BlokCompletion> get _blokCompletionsBox => Hive.box<BlokCompletion>(blokCompletionsBox);
  Box<SagMessage> get _messagesBox => Hive.box<SagMessage>(messagesBox);
  Box<ActivityLog> get _activityLogsBox => Hive.box<ActivityLog>(activityLogsBox);

  Future<void> addBlokCompletion(BlokCompletion completion) async {
    await _blokCompletionsBox.put(completion.id, completion);
    await _syncService.queueChange(
      entityType: 'blok_completion',
      operation: 'upsert',
      payload: completion.toJson(),
    );
    await _logActivity(
      sagId: completion.sagId,
      type: 'blok',
      action: 'update',
      description: 'Færdigmelding: ${completion.amountCompleted} ${completion.completionType}',
      user: completion.user,
    );
  }

  List<BlokCompletion> getBlokCompletionsByBlok(String blokId) {
    return _blokCompletionsBox.values
        .where((completion) => completion.blokId == blokId)
        .toList()
      ..sort((a, b) => b.completionDate.compareTo(a.completionDate));
  }

  List<BlokCompletion> getBlokCompletionsBySag(String sagId) {
    return _blokCompletionsBox.values
        .where((completion) => completion.sagId == sagId)
        .toList();
  }

  // Messages
  Future<void> addMessage(SagMessage message) async {
    await _messagesBox.put(message.id, message);
    await _syncService.queueChange(
      entityType: 'message',
      operation: 'upsert',
      payload: message.toJson(),
    );
    await _logActivity(
      sagId: message.sagId,
      type: 'besked',
      action: 'create',
      description: 'Ny besked fra ${message.userName}',
      user: message.userName,
    );
  }

  List<SagMessage> getMessagesBySag(String sagId) {
    final items = _messagesBox.values.where((m) => m.sagId == sagId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return items;
  }

  List<SagMessage> getAllMessages() {
    return _messagesBox.values.toList();
  }

  // Activity logs
  List<ActivityLog> getActivityLogsBySag(String sagId) {
    final items = _activityLogsBox.values.where((a) => a.sagId == sagId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  List<ActivityLog> getAllActivityLogs() {
    final items = _activityLogsBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  List<ActivityLog> getActivityLogsByEntityType(String entityType) {
    final items = _activityLogsBox.values.where((a) => a.entityType == entityType).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  List<ActivityLog> getActivityLogsByUser(String userId) {
    final items = _activityLogsBox.values.where((a) => a.userId == userId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  /// Get recent activity logs with optional filters
  List<ActivityLog> getRecentActivityLogs({
    int limit = 50,
    String? entityType,
    String? action,
    String? sagId,
    DateTime? since,
  }) {
    var items = _activityLogsBox.values.toList();

    if (entityType != null) {
      items = items.where((a) => a.entityType == entityType).toList();
    }
    if (action != null) {
      items = items.where((a) => a.action == action).toList();
    }
    if (sagId != null) {
      items = items.where((a) => a.sagId == sagId).toList();
    }
    if (since != null) {
      items = items.where((a) {
        try {
          return DateTime.parse(a.timestamp).isAfter(since);
        } catch (_) {
          return false;
        }
      }).toList();
    }

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items.take(limit).toList();
  }

  // Kabel/Slange Logs
  Box<KabelSlangeLog> get _kabelSlangeLogsBox => Hive.box<KabelSlangeLog>(kabelSlangeLogsBox);

  Future<void> addKabelSlangeLog(KabelSlangeLog log) async {
    await _kabelSlangeLogsBox.put(log.id, log);
    await _syncService.queueChange(
      entityType: 'kabel_slange_log',
      operation: 'upsert',
      payload: log.toJson(),
    );
    await _logActivity(
      sagId: log.sagId,
      type: 'kabel',
      action: 'create',
      description: '${log.category} ${log.type} ${log.quantity ?? log.meters ?? ''}'.trim(),
      user: log.user,
    );
  }

  List<KabelSlangeLog> getKabelSlangeLogsBySag(String sagId) {
    return _kabelSlangeLogsBox.values
        .where((log) => log.sagId == sagId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> updateKabelSlangeLog(KabelSlangeLog log) async {
    await _kabelSlangeLogsBox.put(log.id, log);
    await _syncService.queueChange(
      entityType: 'kabel_slange_log',
      operation: 'upsert',
      payload: log.toJson(),
    );
    await _logActivity(
      sagId: log.sagId,
      type: 'kabel',
      action: 'update',
      description: '${log.category} ${log.type} opdateret',
      user: log.user,
    );
  }

  Future<void> deleteKabelSlangeLog(String id) async {
    final existing = _kabelSlangeLogsBox.get(id);
    await _kabelSlangeLogsBox.delete(id);
    await _syncService.queueChange(
      entityType: 'kabel_slange_log',
      operation: 'delete',
      payload: {'id': id},
    );
    await _logActivity(
      sagId: existing?.sagId ?? '',
      type: 'kabel',
      action: 'delete',
      description: 'Kabel/slange log slettet',
    );
  }

  List<KabelSlangeLog> getAllKabelSlangeLogs() {
    return _kabelSlangeLogsBox.values.toList();
  }

  /// Log an activity with detailed change tracking
  Future<void> logActivity({
    required String entityType,
    required String action,
    String? entityId,
    String? sagId,
    String? description,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
    String? userId,
    String? userName,
  }) async {
    final entry = ActivityLog(
      id: _uuid.v4(),
      entityType: entityType,
      action: action,
      entityId: entityId,
      sagId: sagId,
      description: description,
      oldData: oldData,
      newData: newData,
      userId: userId,
      userName: userName,
      timestamp: DateTime.now().toIso8601String(),
    );
    await _activityLogsBox.put(entry.id, entry);
    debugPrint('Activity logged: $entityType/$action${entityId != null ? ' for $entityId' : ''}');

    // Queue the activity log for sync to Supabase
    await _syncService.queueChange(
      entityType: 'activity_log',
      operation: 'upsert',
      payload: entry.toJson(),
    );

    // Notify listeners that activity log has been updated
    _notifyActivityLogListeners(entry);
  }

  // Activity log listeners for real-time updates
  final List<void Function(ActivityLog)> _activityLogListeners = [];

  void addActivityLogListener(void Function(ActivityLog) listener) {
    _activityLogListeners.add(listener);
  }

  void removeActivityLogListener(void Function(ActivityLog) listener) {
    _activityLogListeners.remove(listener);
  }

  void _notifyActivityLogListeners(ActivityLog entry) {
    for (final listener in _activityLogListeners) {
      listener(entry);
    }
  }

  /// Legacy helper for backwards compatibility
  Future<void> _logActivity({
    required String sagId,
    required String type,
    required String action,
    required String description,
    String? user,
  }) async {
    await logActivity(
      entityType: type,
      action: action,
      sagId: sagId,
      description: description,
      userName: user,
    );
  }

  // Initialize sample data (development mode only)
  Future<void> initSampleData() async {
    // Only seed data in debug mode
    if (!kDebugMode) {
      return;
    }

    if (_sagerBox.isNotEmpty) return; // Already initialized

    // Sample users (debug/development credentials only)
    final users = [
      User(
        id: 'user_rasmus',
        name: 'Rasmus',
        pin: '1234',
        role: 'tekniker',
        createdAt: DateTime.now().toIso8601String(),
      ),
      User(
        id: 'user_stefan',
        name: 'Stefan',
        pin: '1235',
        role: 'tekniker',
        createdAt: DateTime.now().toIso8601String(),
      ),
      User(
        id: 'user_christian',
        name: 'Christian',
        pin: '1236',
        role: 'tekniker',
        createdAt: DateTime.now().toIso8601String(),
      ),
      User(
        id: 'user_tanja',
        name: 'Tanja',
        pin: '0000',
        role: 'admin',
        createdAt: DateTime.now().toIso8601String(),
      ),
    ];

    for (var user in users) {
      await addUser(user);
    }

    // Sample sager
    final sager = [
      Sag(
        id: 'sag_001',
        sagsnr: '2024-01',
        adresse: 'Byggevej 123, 2000 Frederiksberg',
        byggeleder: 'Lars Hansen',
        byggelederEmail: 'lars@abc-byg.dk',
        byggelederTlf: '12345678',
        status: 'aktiv',
        aktiv: true,
        sagType: 'udtørring',
        region: 'sjælland',
        oprettetAf: 'user_stefan',
        oprettetDato: DateTime.now().toIso8601String(),
        opdateretDato: DateTime.now().toIso8601String(),
      ),
      Sag(
        id: 'sag_002',
        sagsnr: '2024-02',
        adresse: 'Industrivej 45, 3000 Helsingør',
        byggeleder: 'Mette Nielsen',
        byggelederEmail: 'mette@renovering.dk',
        byggelederTlf: '87654321',
        status: 'aktiv',
        aktiv: true,
        sagType: 'varme',
        region: 'fyn',
        oprettetAf: 'user_christian',
        oprettetDato: DateTime.now().toIso8601String(),
        opdateretDato: DateTime.now().toIso8601String(),
      ),
    ];

    for (var sag in sager) {
      await addSag(sag);
    }

    // Sample affugtere
    final affugtere = [
      Affugter(
        id: 'af_001',
        nr: '2-0001',
        type: 'adsorption',
        maerke: 'Master',
        model: 'DH-750',
        serie: 'M2023001',
        status: 'hjemme',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ),
      Affugter(
        id: 'af_002',
        nr: '2-0002',
        type: 'kondens',
        maerke: 'Fral',
        model: 'FD-520',
        serie: 'F2023002',
        status: 'hjemme',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ),
    ];

    for (var affugter in affugtere) {
      await addAffugter(affugter);
    }

    print('✅ Sample data initialized');
  }

  // Clear all data (for development/testing)
  Future<void> clearAllData() async {
    await _usersBox.clear();
    await _sagerBox.clear();
    await _affugtereBox.clear();
    await _equipmentLogsBox.clear();
    await _timerLogsBox.clear();
    await _blokkeBox.clear();
    await _blokCompletionsBox.clear();
    await _kabelSlangeLogsBox.clear();
    await _messagesBox.clear();
    await _activityLogsBox.clear();
    debugPrint('All data cleared');
  }

  /// Import data from a backup JSON structure
  /// This clears all existing data and replaces it with backup data
  Future<void> importFromBackup(Map<String, dynamic> backupData) async {
    final data = backupData['data'] as Map<String, dynamic>;

    // Clear all existing data first
    await clearAllData();

    // Import users
    if (data['users'] != null) {
      for (final json in data['users'] as List) {
        final user = User.fromJson(Map<String, dynamic>.from(json as Map));
        await _usersBox.put(user.id, user);
      }
      debugPrint('Imported ${(data['users'] as List).length} users');
    }

    // Import sager
    if (data['sager'] != null) {
      for (final json in data['sager'] as List) {
        final sag = Sag.fromJson(Map<String, dynamic>.from(json as Map));
        await _sagerBox.put(sag.id, sag);
      }
      debugPrint('Imported ${(data['sager'] as List).length} sager');
    }

    // Import affugtere
    if (data['affugtere'] != null) {
      for (final json in data['affugtere'] as List) {
        final affugter = Affugter.fromJson(Map<String, dynamic>.from(json as Map));
        await _affugtereBox.put(affugter.id, affugter);
      }
      debugPrint('Imported ${(data['affugtere'] as List).length} affugtere');
    }

    // Import blokke
    if (data['blokke'] != null) {
      for (final json in data['blokke'] as List) {
        final blok = Blok.fromJson(Map<String, dynamic>.from(json as Map));
        await _blokkeBox.put(blok.id, blok);
      }
      debugPrint('Imported ${(data['blokke'] as List).length} blokke');
    }

    // Import equipment logs
    if (data['equipmentLogs'] != null) {
      for (final json in data['equipmentLogs'] as List) {
        final log = EquipmentLog.fromJson(Map<String, dynamic>.from(json as Map));
        await _equipmentLogsBox.put(log.id, log);
      }
      debugPrint('Imported ${(data['equipmentLogs'] as List).length} equipment logs');
    }

    // Import timer logs
    if (data['timerLogs'] != null) {
      for (final json in data['timerLogs'] as List) {
        final log = TimerLog.fromJson(Map<String, dynamic>.from(json as Map));
        await _timerLogsBox.put(log.id, log);
      }
      debugPrint('Imported ${(data['timerLogs'] as List).length} timer logs');
    }

    // Import kabel/slange logs
    if (data['kabelSlangeLogs'] != null) {
      for (final json in data['kabelSlangeLogs'] as List) {
        final log = KabelSlangeLog.fromJson(Map<String, dynamic>.from(json as Map));
        await _kabelSlangeLogsBox.put(log.id, log);
      }
      debugPrint('Imported ${(data['kabelSlangeLogs'] as List).length} kabel/slange logs');
    }

    // Import messages
    if (data['messages'] != null) {
      for (final json in data['messages'] as List) {
        final message = SagMessage.fromJson(Map<String, dynamic>.from(json as Map));
        await _messagesBox.put(message.id, message);
      }
      debugPrint('Imported ${(data['messages'] as List).length} messages');
    }

    // Import activity logs
    if (data['activityLogs'] != null) {
      for (final json in data['activityLogs'] as List) {
        final log = ActivityLog.fromJson(Map<String, dynamic>.from(json as Map));
        await _activityLogsBox.put(log.id, log);
      }
      debugPrint('Imported ${(data['activityLogs'] as List).length} activity logs');
    }

    // Queue all imported data for sync to Supabase
    await _queueAllDataForSync();

    debugPrint('Backup import completed successfully');
  }

  /// Queue all current data for sync to Supabase
  Future<void> _queueAllDataForSync() async {
    // Queue users
    for (final user in _usersBox.values) {
      await _syncService.queueChange(
        entityType: 'user',
        operation: 'upsert',
        payload: user.toJson(),
      );
    }

    // Queue sager
    for (final sag in _sagerBox.values) {
      await _syncService.queueChange(
        entityType: 'sag',
        operation: 'upsert',
        payload: sag.toJson(),
      );
    }

    // Queue affugtere
    for (final affugter in _affugtereBox.values) {
      await _syncService.queueChange(
        entityType: 'affugter',
        operation: 'upsert',
        payload: affugter.toJson(),
      );
    }

    // Queue blokke
    for (final blok in _blokkeBox.values) {
      await _syncService.queueChange(
        entityType: 'blok',
        operation: 'upsert',
        payload: blok.toJson(),
      );
    }

    // Queue equipment logs
    for (final log in _equipmentLogsBox.values) {
      await _syncService.queueChange(
        entityType: 'equipment_log',
        operation: 'upsert',
        payload: log.toJson(),
      );
    }

    // Queue timer logs
    for (final log in _timerLogsBox.values) {
      await _syncService.queueChange(
        entityType: 'timer_log',
        operation: 'upsert',
        payload: log.toJson(),
      );
    }

    // Queue kabel/slange logs
    for (final log in _kabelSlangeLogsBox.values) {
      await _syncService.queueChange(
        entityType: 'kabel_slange_log',
        operation: 'upsert',
        payload: log.toJson(),
      );
    }

    // Queue messages
    for (final message in _messagesBox.values) {
      await _syncService.queueChange(
        entityType: 'message',
        operation: 'upsert',
        payload: message.toJson(),
      );
    }

    // Queue activity logs
    for (final log in _activityLogsBox.values) {
      await _syncService.queueChange(
        entityType: 'activity_log',
        operation: 'upsert',
        payload: log.toJson(),
      );
    }

    debugPrint('All data queued for sync');
  }

  // Generate unique ID
  String generateId() => _uuid.v4();
}
