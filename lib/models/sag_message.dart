import 'package:hive/hive.dart';

part 'sag_message.g.dart';

@HiveType(typeId: 9)
class SagMessage extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String sagId;

  @HiveField(2)
  String userId;

  @HiveField(3)
  String userName;

  @HiveField(4)
  String text;

  @HiveField(5)
  String timestamp; // ISO string

  /// Target employee ID - null means message is for all employees
  @HiveField(6)
  String? targetUserId;

  /// Target employee name - for display purposes
  @HiveField(7)
  String? targetUserName;

  SagMessage({
    required this.id,
    required this.sagId,
    required this.userId,
    required this.userName,
    required this.text,
    required this.timestamp,
    this.targetUserId,
    this.targetUserName,
  });

  /// Check if message is targeted to a specific employee
  bool get isTargeted => targetUserId != null;

  /// Check if message should be visible to a specific user
  bool isVisibleTo(String userId) {
    // Message is visible if it's not targeted (for all) or targeted to this user
    // Also visible to the sender
    return targetUserId == null || targetUserId == userId || this.userId == userId;
  }

  /// Get display string for target
  String get targetDisplayName {
    if (targetUserId == null) return 'Alle';
    return targetUserName ?? 'Ukendt';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sagId': sagId,
        'userId': userId,
        'userName': userName,
        'text': text,
        'timestamp': timestamp,
        'targetUserId': targetUserId,
        'targetUserName': targetUserName,
      };

  factory SagMessage.fromJson(Map<String, dynamic> json) => SagMessage(
        id: json['id'] as String,
        sagId: json['sagId'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        text: json['text'] as String,
        timestamp: json['timestamp'] as String,
        targetUserId: json['targetUserId'] as String?,
        targetUserName: json['targetUserName'] as String?,
      );
}
