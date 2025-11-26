import 'package:hive/hive.dart';

part 'timer_log.g.dart';

@HiveType(typeId: 4)
class TimerLog extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String sagId;

  @HiveField(2)
  String date;

  @HiveField(3)
  String type;

  @HiveField(4)
  String? customType;

  @HiveField(5)
  double hours;

  @HiveField(6)
  double rate;

  @HiveField(7)
  bool billable;

  @HiveField(8)
  String? note;

  @HiveField(9)
  String user;

  @HiveField(10)
  String timestamp;

  TimerLog({
    required this.id,
    required this.sagId,
    required this.date,
    required this.type,
    this.customType,
    required this.hours,
    required this.rate,
    required this.billable,
    this.note,
    required this.user,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sagId': sagId,
        'date': date,
        'type': type,
        'customType': customType,
        'hours': hours,
        'rate': rate,
        'billable': billable,
        'note': note,
        'user': user,
        'timestamp': timestamp,
      };

  factory TimerLog.fromJson(Map<String, dynamic> json) => TimerLog(
        id: json['id'] as String,
        sagId: json['sagId'] as String,
        date: json['date'] as String,
        type: json['type'] as String,
        customType: json['customType'] as String?,
        hours: (json['hours'] as num).toDouble(),
        rate: (json['rate'] as num).toDouble(),
        billable: json['billable'] as bool,
        note: json['note'] as String?,
        user: json['user'] as String,
        timestamp: json['timestamp'] as String,
      );
}
