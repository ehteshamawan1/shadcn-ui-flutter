import 'package:hive/hive.dart';

part 'blok.g.dart';

@HiveType(typeId: 5)
class Blok extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String sagId;

  @HiveField(2)
  String navn;

  @HiveField(3)
  String? beskrivelse;

  @HiveField(4)
  String pricingModel; // 'dagsleje' | 'fast_pris_per_lejlighed' | 'fast_pris_per_m2'

  @HiveField(5)
  int antalLejligheder;

  @HiveField(6)
  double antalM2;

  @HiveField(7)
  double fastPrisPrLejlighed;

  @HiveField(8)
  double fastPrisPrM2;

  @HiveField(9)
  int faerdigmeldteLejligheder;

  @HiveField(10)
  double faerdigmeldteM2;

  @HiveField(11)
  String? slutDato;

  @HiveField(12)
  String createdAt;

  @HiveField(13)
  String updatedAt;

  Blok({
    required this.id,
    required this.sagId,
    required this.navn,
    this.beskrivelse,
    required this.pricingModel,
    this.antalLejligheder = 0,
    this.antalM2 = 0,
    this.fastPrisPrLejlighed = 0,
    this.fastPrisPrM2 = 0,
    this.faerdigmeldteLejligheder = 0,
    this.faerdigmeldteM2 = 0,
    this.slutDato,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sagId': sagId,
        'navn': navn,
        'beskrivelse': beskrivelse,
        'pricingModel': pricingModel,
        'antalLejligheder': antalLejligheder,
        'antalM2': antalM2,
        'fastPrisPrLejlighed': fastPrisPrLejlighed,
        'fastPrisPrM2': fastPrisPrM2,
        'faerdigmeldteLejligheder': faerdigmeldteLejligheder,
        'faerdigmeldteM2': faerdigmeldteM2,
        'slutDato': slutDato,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory Blok.fromJson(Map<String, dynamic> json) => Blok(
        id: json['id'] as String,
        sagId: json['sagId'] as String,
        navn: json['navn'] as String,
        beskrivelse: json['beskrivelse'] as String?,
        pricingModel: json['pricingModel'] as String,
        antalLejligheder: json['antalLejligheder'] as int? ?? 0,
        antalM2: (json['antalM2'] as num?)?.toDouble() ?? 0,
        fastPrisPrLejlighed: (json['fastPrisPrLejlighed'] as num?)?.toDouble() ?? 0,
        fastPrisPrM2: (json['fastPrisPrM2'] as num?)?.toDouble() ?? 0,
        faerdigmeldteLejligheder: json['faerdigmeldteLejligheder'] as int? ?? 0,
        faerdigmeldteM2: (json['faerdigmeldteM2'] as num?)?.toDouble() ?? 0,
        slutDato: json['slutDato'] as String?,
        createdAt: json['createdAt'] as String,
        updatedAt: json['updatedAt'] as String,
      );

  double calculateProgress() {
    if (pricingModel == 'fast_pris_per_lejlighed' && antalLejligheder > 0) {
      return (faerdigmeldteLejligheder / antalLejligheder) * 100;
    } else if (pricingModel == 'fast_pris_per_m2' && antalM2 > 0) {
      return (faerdigmeldteM2 / antalM2) * 100;
    }
    return 0;
  }
}
