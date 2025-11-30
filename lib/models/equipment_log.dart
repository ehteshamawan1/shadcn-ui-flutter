import 'package:hive/hive.dart';

part 'equipment_log.g.dart';

@HiveType(typeId: 3)
class EquipmentLog extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String sagId;

  @HiveField(2)
  String? blokId;

  @HiveField(3)
  String category;

  @HiveField(4)
  String action; // 'opsæt', 'nedtag', 'tilføj', 'defekt', 'afmeld'

  @HiveField(5)
  Map<String, dynamic> data;

  @HiveField(6)
  String timestamp;

  @HiveField(7)
  String user;

  @HiveField(8)
  String? note;

  EquipmentLog({
    required this.id,
    required this.sagId,
    this.blokId,
    required this.category,
    required this.action,
    required this.data,
    required this.timestamp,
    required this.user,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sagId': sagId,
        'blokId': blokId,
        'category': category,
        'action': action,
        'data': data,
        'timestamp': timestamp,
        'userId': user,
        'note': note,
      };

  factory EquipmentLog.fromJson(Map<String, dynamic> json) => EquipmentLog(
        id: json['id'] as String,
        sagId: json['sagId'] as String,
        blokId: json['blokId'] as String?,
        category: json['category'] as String,
        action: json['action'] as String,
        data: Map<String, dynamic>.from(json['data'] as Map),
        timestamp: json['timestamp'] as String,
        user: (json['userId'] ?? json['user']) as String,
        note: json['note'] as String?,
      );
}
