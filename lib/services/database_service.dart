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

  final _uuid = const Uuid();
  final SyncService _syncService = SyncService();

  Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters (guard against duplicate registration for hot restarts)
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
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(SagMessageAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(KabelSlangeLogAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(ActivityLogAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(AppSettingAdapter());
    }

    try {
      // Open boxes
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
    } catch (e) {
      // If we get a HiveError with unknown typeId, clear all boxes and retry
      if (e.toString().contains('unknown typeId') || e.toString().contains('HiveError')) {
        debugPrint('Hive database incompatibility detected. Clearing database...');
        await _clearAllBoxes();

        // Retry opening boxes after clearing
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
      } else {
        rethrow;
      }
    }

    // Initialize sample data if needed
    await initSampleData();

    // Initialize settings service
    await SettingsService().init();
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
      debugPrint('All Hive boxes cleared successfully');
    } catch (e) {
      debugPrint('Error clearing boxes: $e');
    }
  }

  // Users
  Box<User> get _usersBox => Hive.box<User>(usersBox);

  Future<void> addUser(User user) async {
    await _usersBox.put(user.id, user);
    await _syncService.queueChange(
      entityType: 'user',
      operation: 'upsert',
      payload: user.toJson(),
    );
  }

  Future<void> updateUser(User user) async {
    await _usersBox.put(user.id, user);
    await _syncService.queueChange(
      entityType: 'user',
      operation: 'upsert',
      payload: user.toJson(),
    );
  }

  Future<User?> getUser(String id) async {
    return _usersBox.get(id);
  }

  List<User> getAllUsers() {
    return _usersBox.values.toList();
  }

  Future<void> deleteUser(String id) async {
    await _usersBox.delete(id);
    await _syncService.queueChange(
      entityType: 'user',
      operation: 'delete',
      payload: {'id': id},
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

  Future<void> addAffugter(Affugter affugter) async {
    await _affugtereBox.put(affugter.id, affugter);
    await _syncService.queueChange(
      entityType: 'affugter',
      operation: 'upsert',
      payload: affugter.toJson(),
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

  Future<void> updateAffugter(Affugter affugter) async {
    await _affugtereBox.put(affugter.id, affugter);
    await _syncService.queueChange(
      entityType: 'affugter',
      operation: 'upsert',
      payload: affugter.toJson(),
    );
  }

  Future<void> deleteAffugter(String id) async {
    await _affugtereBox.delete(id);
    await _syncService.queueChange(
      entityType: 'affugter',
      operation: 'delete',
      payload: {'id': id},
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

  // Activity logs
  List<ActivityLog> getActivityLogsBySag(String sagId) {
    final items = _activityLogsBox.values.where((a) => a.sagId == sagId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
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

  Future<void> _logActivity({
    required String sagId,
    required String type,
    required String action,
    required String description,
    String? user,
  }) async {
    final entry = ActivityLog(
      id: _uuid.v4(),
      sagId: sagId,
      type: type,
      action: action,
      description: description,
      timestamp: DateTime.now().toIso8601String(),
      user: user,
    );
    await _activityLogsBox.put(entry.id, entry);
    debugPrint('Activity logged: $type/$action for sag $sagId');

    // Queue the activity log for sync to Supabase
    await _syncService.queueChange(
      entityType: 'activity_log',
      operation: 'upsert',
      payload: entry.toJson(),
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
    print('🗑️ All data cleared');
  }

  // Generate unique ID
  String generateId() => _uuid.v4();
}
