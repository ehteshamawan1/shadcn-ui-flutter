import 'package:hive/hive.dart';

/// Simple representation of an action that needs to be synced to the cloud
/// when the device is online again.
class SyncTask {
  SyncTask({
    required this.id,
    required this.entityType,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.lastTriedAt,
    this.attempts = 0,
  });

  final String id;
  final String entityType; // e.g. 'sag', 'affugter', 'equipment_log', 'timer_log', 'user'
  final String operation; // 'upsert' | 'delete'
  final Map<String, dynamic> payload;
  final String createdAt;
  final String? lastTriedAt;
  final int attempts;
}

/// Manual Hive adapter (to avoid running code generation for a single type)
class SyncTaskAdapter extends TypeAdapter<SyncTask> {
  @override
  final int typeId = 7;

  @override
  SyncTask read(BinaryReader reader) {
    final id = reader.readString();
    final entityType = reader.readString();
    final operation = reader.readString();
    final payload = Map<String, dynamic>.from(reader.readMap());
    final createdAt = reader.readString();
    final lastTriedRaw = reader.readString();
    final attempts = reader.readInt();

    return SyncTask(
      id: id,
      entityType: entityType,
      operation: operation,
      payload: payload,
      createdAt: createdAt,
      lastTriedAt: lastTriedRaw.isEmpty ? null : lastTriedRaw,
      attempts: attempts,
    );
  }

  @override
  void write(BinaryWriter writer, SyncTask obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.entityType)
      ..writeString(obj.operation)
      ..writeMap(obj.payload)
      ..writeString(obj.createdAt)
      ..writeString(obj.lastTriedAt ?? '')
      ..writeInt(obj.attempts);
  }
}
