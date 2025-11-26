import 'package:hive/hive.dart';

part 'kabel_slange_log.g.dart';

@HiveType(typeId: 8)
class KabelSlangeLog extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String sagId;

  /// 'slanger' eller 'kabler'
  @HiveField(2)
  String category;

  @HiveField(3)
  String type;

  @HiveField(4)
  String? customType;

  @HiveField(5)
  double? meters;

  @HiveField(6)
  int? quantity;

  @HiveField(7)
  double? pricePerMeter;

  @HiveField(8)
  double? totalPrice;

  @HiveField(9)
  String? note;

  @HiveField(10)
  String? user;

  @HiveField(11)
  String timestamp;

  KabelSlangeLog({
    required this.id,
    required this.sagId,
    required this.category,
    required this.type,
    this.customType,
    this.meters,
    this.quantity,
    this.pricePerMeter,
    this.totalPrice,
    this.note,
    this.user,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sagId': sagId,
        'category': category,
        'type': type,
        'customType': customType,
        'meters': meters,
        'quantity': quantity,
        'pricePerMeter': pricePerMeter,
        'totalPrice': totalPrice,
        'note': note,
        'user': user,
        'timestamp': timestamp,
      };

  factory KabelSlangeLog.fromJson(Map<String, dynamic> json) => KabelSlangeLog(
        id: json['id'] as String,
        sagId: json['sagId'] as String,
        category: json['category'] as String,
        type: json['type'] as String,
        customType: json['customType'] as String?,
        meters: (json['meters'] as num?)?.toDouble(),
        quantity: json['quantity'] as int?,
        pricePerMeter: (json['pricePerMeter'] as num?)?.toDouble(),
        totalPrice: (json['totalPrice'] as num?)?.toDouble(),
        note: json['note'] as String?,
        user: json['user'] as String?,
        timestamp: json['timestamp'] as String,
      );
}
