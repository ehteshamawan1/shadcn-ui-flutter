import 'package:hive/hive.dart';

part 'blok_completion.g.dart';

@HiveType(typeId: 6)
class BlokCompletion extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String blokId;

  @HiveField(2)
  String sagId;

  @HiveField(3)
  String completionDate;

  @HiveField(4)
  String completionType; // 'lejligheder' | 'm2'

  @HiveField(5)
  double previousAmount;

  @HiveField(6)
  double newAmount;

  @HiveField(7)
  double amountCompleted;

  @HiveField(8)
  String user;

  @HiveField(9)
  String? note;

  @HiveField(10)
  String createdAt;

  BlokCompletion({
    required this.id,
    required this.blokId,
    required this.sagId,
    required this.completionDate,
    required this.completionType,
    required this.previousAmount,
    required this.newAmount,
    required this.amountCompleted,
    required this.user,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'blokId': blokId,
        'sagId': sagId,
        'completionDate': completionDate,
        'completionType': completionType,
        'previousAmount': previousAmount,
        'newAmount': newAmount,
        'amountCompleted': amountCompleted,
        'user': user,
        'note': note,
        'createdAt': createdAt,
      };

  factory BlokCompletion.fromJson(Map<String, dynamic> json) => BlokCompletion(
        id: json['id'] as String,
        blokId: json['blokId'] as String,
        sagId: json['sagId'] as String,
        completionDate: json['completionDate'] as String,
        completionType: json['completionType'] as String,
        previousAmount: (json['previousAmount'] as num).toDouble(),
        newAmount: (json['newAmount'] as num).toDouble(),
        amountCompleted: (json['amountCompleted'] as num).toDouble(),
        user: json['user'] as String,
        note: json['note'] as String?,
        createdAt: json['createdAt'] as String,
      );
}
