import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SagNotification {
  final String sagId;
  final String type;
  final String timestamp;
  final String message;
  final Map<String, dynamic>? details;

  SagNotification({
    required this.sagId,
    required this.type,
    required this.timestamp,
    required this.message,
    this.details,
  });

  Map<String, dynamic> toJson() => {
        'sagId': sagId,
        'type': type,
        'timestamp': timestamp,
        'message': message,
        'details': details,
      };

  factory SagNotification.fromJson(Map<String, dynamic> json) {
    return SagNotification(
      sagId: json['sagId'] as String,
      type: json['type'] as String,
      timestamp: json['timestamp'] as String,
      message: json['message'] as String,
      details: json['details'] != null ? Map<String, dynamic>.from(json['details'] as Map) : null,
    );
  }
}

class NotificationState {
  final List<SagNotification> notifications;
  final List<String> acknowledgedSager;
  final String lastChecked;

  NotificationState({
    required this.notifications,
    required this.acknowledgedSager,
    required this.lastChecked,
  });

  factory NotificationState.empty() => NotificationState(
        notifications: [],
        acknowledgedSager: [],
        lastChecked: DateTime.now().toIso8601String(),
      );

  Map<String, dynamic> toJson() => {
        'notifications': notifications.map((n) => n.toJson()).toList(),
        'acknowledgedSager': acknowledgedSager,
        'lastChecked': lastChecked,
      };

  factory NotificationState.fromJson(Map<String, dynamic> json) {
    final notificationsJson = json['notifications'] as List? ?? [];
    final acknowledgedJson = json['acknowledgedSager'] as List? ?? [];

    return NotificationState(
      notifications: notificationsJson
          .map((n) => SagNotification.fromJson(Map<String, dynamic>.from(n as Map)))
          .toList(),
      acknowledgedSager: acknowledgedJson.map((id) => id.toString()).toList(),
      lastChecked: json['lastChecked'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}

class NotificationManager {
  NotificationManager._internal();
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;

  static const String _storageKey = 'ska_dan_notifications';

  NotificationState _state = NotificationState.empty();
  bool _initialized = false;

  final List<VoidCallback> _listeners = [];

  Future<void> init() async {
    if (_initialized) return;
    _state = await _loadState();
    _initialized = true;
  }

  Future<NotificationState> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKey);
      if (stored == null || stored.isEmpty) {
        return NotificationState.empty();
      }
      return NotificationState.fromJson(jsonDecode(stored) as Map<String, dynamic>);
    } catch (error) {
      debugPrint('Error loading notification state: $error');
      return NotificationState.empty();
    }
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_state.toJson()));
    } catch (error) {
      debugPrint('Error saving notification state: $error');
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }

  Future<SagNotification> addEquipmentNotification(
    String sagId,
    String type,
    Map<String, dynamic> details,
  ) async {
    await _ensureInitialized();

    final notification = SagNotification(
      sagId: sagId,
      type: type,
      timestamp: DateTime.now().toIso8601String(),
      message: _generateEquipmentMessage(type, details),
      details: details,
    );

    _state.notifications.add(notification);
    _state.acknowledgedSager.removeWhere((id) => id == sagId);

    await _saveState();
    _notifyListeners();
    return notification;
  }

  Future<SagNotification> addTimerNotification(String sagId, Map<String, dynamic> details) async {
    await _ensureInitialized();

    final notification = SagNotification(
      sagId: sagId,
      type: 'timer_activity',
      timestamp: DateTime.now().toIso8601String(),
      message: _generateTimerMessage(details),
      details: details,
    );

    _state.notifications.add(notification);
    _state.acknowledgedSager.removeWhere((id) => id == sagId);

    await _saveState();
    _notifyListeners();
    return notification;
  }

  Future<SagNotification> addBlokNotification(String sagId, Map<String, dynamic> details) async {
    await _ensureInitialized();

    final notification = SagNotification(
      sagId: sagId,
      type: 'blok_updated',
      timestamp: DateTime.now().toIso8601String(),
      message: _generateBlokMessage(details),
      details: details,
    );

    _state.notifications.add(notification);
    _state.acknowledgedSager.removeWhere((id) => id == sagId);

    await _saveState();
    _notifyListeners();
    return notification;
  }

  Future<void> acknowledgeSag(String sagId) async {
    await _ensureInitialized();

    if (!_state.acknowledgedSager.contains(sagId)) {
      _state.acknowledgedSager.add(sagId);
      await _saveState();
      _notifyListeners();
    }
  }

  List<String> getSagerNeedingAttention() {
    final sagerWithNotifications = _state.notifications.map((n) => n.sagId).toSet().toList();
    return sagerWithNotifications.where((id) => !_state.acknowledgedSager.contains(id)).toList();
  }

  List<SagNotification> getNotificationsForSag(String sagId) {
    final items = _state.notifications.where((n) => n.sagId == sagId).toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  int getAttentionCount() => getSagerNeedingAttention().length;

  bool sagNeedsAttention(String sagId) => getSagerNeedingAttention().contains(sagId);

  List<SagNotification> getRecentNotifications() {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final items = _state.notifications.where((n) {
      final ts = DateTime.tryParse(n.timestamp);
      return ts != null && ts.isAfter(cutoff);
    }).toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  Future<void> cleanupOldNotifications() async {
    await _ensureInitialized();
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    _state = NotificationState(
      notifications: _state.notifications.where((n) {
        final ts = DateTime.tryParse(n.timestamp);
        return ts != null && ts.isAfter(cutoff);
      }).toList(),
      acknowledgedSager: _state.acknowledgedSager,
      lastChecked: _state.lastChecked,
    );
    await _saveState();
  }

  VoidCallback subscribe(VoidCallback listener) {
    _listeners.add(listener);
    return () {
      _listeners.remove(listener);
    };
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      try {
        listener();
      } catch (error) {
        debugPrint('Error in notification listener: $error');
      }
    }
  }

  String _generateEquipmentMessage(String type, Map<String, dynamic> details) {
    final action = type == 'equipment_added' ? 'tilfA,jet' : 'nedtaget';
    final quantity = details['quantity'] ?? 1;
    final category = details['category'] ?? '';
    final equipmentType = details['type'] ?? '';
    final blokNavn = details['blokNavn'];
    final blokSuffix = blokNavn != null && blokNavn.toString().isNotEmpty ? ' i $blokNavn' : '';
    return '$quantity $category $equipmentType $action$blokSuffix';
  }

  String _generateTimerMessage(Map<String, dynamic> details) {
    final action = details['action'] as String?;
    final category = details['category']?.toString().trim() ?? '';
    final type = details['type']?.toString().trim() ?? '';
    final label = [category, type].where((v) => v.isNotEmpty).join(' ');

    if (action == 'started') {
      return 'Timer startet for $label'.trim();
    }
    if (action == 'stopped') {
      final duration = details['duration'];
      final durationLabel = duration != null ? ' (${(duration as num).round()} min)' : '';
      return 'Timer stoppet for $label$durationLabel'.trim();
    }
    return 'Timer aktivitet registreret';
  }

  String _generateBlokMessage(Map<String, dynamic> details) {
    final action = details['action'] as String?;
    final navn = details['navn'] ?? '';
    if (action == 'created') {
      return 'Ny blok "$navn" oprettet';
    }
    if (action == 'completed') {
      return 'Blok "$navn" markeret som fAÝrdig';
    }
    if (action == 'updated') {
      return 'Blok "$navn" opdateret';
    }
    return 'Blok aktivitet registreret';
  }
}
