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

  SagMessage({
    required this.id,
    required this.sagId,
    required this.userId,
    required this.userName,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sagId': sagId,
        'userId': userId,
        'userName': userName,
        'text': text,
        'timestamp': timestamp,
      };

  factory SagMessage.fromJson(Map<String, dynamic> json) => SagMessage(
        id: json['id'] as String,
        sagId: json['sagId'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        text: json['text'] as String,
        timestamp: json['timestamp'] as String,
      );
}
