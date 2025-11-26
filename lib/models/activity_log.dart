import 'package:hive/hive.dart';

class ActivityLog extends HiveObject {
  ActivityLog({
    required this.id,
    required this.sagId,
    required this.type,
    required this.action,
    required this.description,
    required this.timestamp,
    this.user,
  });

  final String id;
  final String sagId;
  final String type; // e.g. 'timer', 'equipment', 'blok', 'kabel', 'sag', 'besked'
  final String action; // e.g. 'create', 'update', 'delete'
  final String description;
  final String timestamp; // ISO string
  final String? user;

  Map<String, dynamic> toJson() => {
        'id': id,
        'sag_id': sagId,
        'type': type,
        'action': action,
        'description': description,
        'timestamp': timestamp,
        'user': user,
      };

  factory ActivityLog.fromJson(Map<String, dynamic> json) => ActivityLog(
        id: json['id'] as String,
        sagId: json['sag_id'] as String? ?? json['sagId'] as String,
        type: json['type'] as String,
        action: json['action'] as String,
        description: json['description'] as String,
        timestamp: json['timestamp'] as String,
        user: json['user'] as String?,
      );
}

class ActivityLogAdapter extends TypeAdapter<ActivityLog> {
  @override
  final int typeId = 10;

  @override
  ActivityLog read(BinaryReader reader) {
    final id = reader.readString();
    final sagId = reader.readString();
    final type = reader.readString();
    final action = reader.readString();
    final description = reader.readString();
    final timestamp = reader.readString();
    final userStr = reader.readString();

    return ActivityLog(
      id: id,
      sagId: sagId,
      type: type,
      action: action,
      description: description,
      timestamp: timestamp,
      user: userStr.isEmpty ? null : userStr,
    );
  }

  @override
  void write(BinaryWriter writer, ActivityLog obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.sagId)
      ..writeString(obj.type)
      ..writeString(obj.action)
      ..writeString(obj.description)
      ..writeString(obj.timestamp)
      ..writeString(obj.user ?? '');
  }
}
