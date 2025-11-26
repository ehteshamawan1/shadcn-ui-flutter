import 'package:hive/hive.dart';

part 'affugter.g.dart';

@HiveType(typeId: 2)
class Affugter extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nr; // Unique number (2-2345, 1-0123, etc.)

  @HiveField(2)
  String type; // 'adsorption', 'kondens'

  @HiveField(3)
  String maerke; // 'Master', 'Fral', 'Qube', 'Andet'

  @HiveField(4)
  String? model;

  @HiveField(5)
  String? serie;

  @HiveField(6)
  String status; // 'hjemme', 'udlejet', 'defekt'

  @HiveField(7)
  String? currentSagId;

  @HiveField(8)
  String? note;

  @HiveField(9)
  String createdAt;

  @HiveField(10)
  String updatedAt;

  Affugter({
    required this.id,
    required this.nr,
    required this.type,
    required this.maerke,
    this.model,
    this.serie,
    required this.status,
    this.currentSagId,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nr': nr,
        'type': type,
        'mærke': maerke,
        'model': model,
        'serie': serie,
        'status': status,
        'currentSagId': currentSagId,
        'note': note,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory Affugter.fromJson(Map<String, dynamic> json) => Affugter(
        id: json['id'] as String,
        nr: json['nr'] as String,
        type: json['type'] as String,
        maerke: json['mærke'] as String,
        model: json['model'] as String?,
        serie: json['serie'] as String?,
        status: json['status'] as String,
        currentSagId: json['currentSagId'] as String?,
        note: json['note'] as String?,
        createdAt: json['createdAt'] as String,
        updatedAt: json['updatedAt'] as String,
      );
}
