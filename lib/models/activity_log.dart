import 'dart:convert';
import 'package:hive/hive.dart';

class ActivityLog extends HiveObject {
  ActivityLog({
    required this.id,
    required this.entityType,
    required this.action,
    required this.timestamp,
    this.entityId,
    this.sagId,
    this.description,
    this.oldData,
    this.newData,
    this.userId,
    this.userName,
  });

  final String id;
  final String entityType; // e.g. 'sag', 'user', 'affugter', 'timer', 'equipment', 'blok', 'kabel', 'besked', 'settings'
  final String action; // e.g. 'create', 'update', 'delete', 'assign', 'unassign', 'archive'
  final String timestamp; // ISO string
  final String? entityId; // ID of the entity being changed
  final String? sagId; // Related sag ID (for filtering by sag)
  final String? description; // Human-readable description
  final Map<String, dynamic>? oldData; // Previous values (for updates)
  final Map<String, dynamic>? newData; // New values (for creates/updates)
  final String? userId; // ID of user who made the change
  final String? userName; // Name of user who made the change

  Map<String, dynamic> toJson() => {
        'id': id,
        'entityType': entityType,
        'entityId': entityId,
        'action': action,
        'description': description,
        'oldData': oldData,
        'newData': newData,
        'userId': userId,
        'userName': userName,
        'timestamp': timestamp,
        'createdAt': timestamp,
      };

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    // Parse oldData - handle both string and map
    Map<String, dynamic>? parsedOldData;
    if (json['oldData'] != null) {
      if (json['oldData'] is String) {
        try {
          parsedOldData = jsonDecode(json['oldData'] as String) as Map<String, dynamic>;
        } catch (_) {
          parsedOldData = null;
        }
      } else if (json['oldData'] is Map) {
        parsedOldData = Map<String, dynamic>.from(json['oldData'] as Map);
      }
    }

    // Parse newData - handle both string and map
    Map<String, dynamic>? parsedNewData;
    if (json['newData'] != null) {
      if (json['newData'] is String) {
        try {
          parsedNewData = jsonDecode(json['newData'] as String) as Map<String, dynamic>;
        } catch (_) {
          parsedNewData = null;
        }
      } else if (json['newData'] is Map) {
        parsedNewData = Map<String, dynamic>.from(json['newData'] as Map);
      }
    }

    // Support both old schema (type/sag_id/user) and new schema (entityType/entityId/userId)
    return ActivityLog(
      id: json['id'] as String,
      entityType: json['entityType'] as String? ?? json['type'] as String? ?? 'unknown',
      entityId: json['entityId'] as String?,
      action: json['action'] as String,
      description: json['description'] as String?,
      oldData: parsedOldData,
      newData: parsedNewData,
      userId: json['userId'] as String?,
      userName: json['userName'] as String? ?? json['user'] as String?,
      timestamp: json['timestamp'] as String,
      sagId: json['sagId'] as String? ?? json['sag_id'] as String?,
    );
  }

  /// Get a display-friendly description of the change
  String get displayDescription {
    if (description != null && description!.isNotEmpty) {
      return description!;
    }

    // Generate description from action and entity type
    final actionText = switch (action) {
      'create' => 'oprettet',
      'update' => 'opdateret',
      'delete' => 'slettet',
      'assign' => 'tildelt',
      'unassign' => 'fjernet',
      'archive' => 'arkiveret',
      _ => action,
    };

    final entityText = switch (entityType) {
      'sag' => 'Sag',
      'user' => 'Bruger',
      'affugter' => 'Affugter',
      'timer' => 'Timer',
      'equipment' => 'Udstyr',
      'blok' => 'Blok',
      'kabel' => 'Kabel/Slange',
      'besked' => 'Besked',
      'settings' => 'Indstillinger',
      _ => entityType,
    };

    return '$entityText $actionText';
  }
}

class ActivityLogAdapter extends TypeAdapter<ActivityLog> {
  @override
  final int typeId = 10;

  @override
  ActivityLog read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }

    return ActivityLog(
      id: fields[0] as String,
      entityType: fields[1] as String,
      action: fields[2] as String,
      timestamp: fields[3] as String,
      entityId: fields[4] as String?,
      sagId: fields[5] as String?,
      description: fields[6] as String?,
      oldData: fields[7] != null ? Map<String, dynamic>.from(fields[7] as Map) : null,
      newData: fields[8] != null ? Map<String, dynamic>.from(fields[8] as Map) : null,
      userId: fields[9] as String?,
      userName: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ActivityLog obj) {
    writer.writeByte(11); // Number of fields
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.entityType);
    writer.writeByte(2);
    writer.write(obj.action);
    writer.writeByte(3);
    writer.write(obj.timestamp);
    writer.writeByte(4);
    writer.write(obj.entityId);
    writer.writeByte(5);
    writer.write(obj.sagId);
    writer.writeByte(6);
    writer.write(obj.description);
    writer.writeByte(7);
    writer.write(obj.oldData);
    writer.writeByte(8);
    writer.write(obj.newData);
    writer.writeByte(9);
    writer.write(obj.userId);
    writer.writeByte(10);
    writer.write(obj.userName);
  }
}
