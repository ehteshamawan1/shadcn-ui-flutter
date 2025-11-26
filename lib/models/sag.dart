import 'package:hive/hive.dart';

part 'sag.g.dart';

@HiveType(typeId: 1)
class Sag extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String sagsnr;

  @HiveField(2)
  String adresse;

  @HiveField(3)
  String byggeleder;

  @HiveField(4)
  String? byggelederEmail;

  @HiveField(5)
  String? byggelederTlf;

  @HiveField(6)
  String? bygherre;

  @HiveField(7)
  String? cvrNr;

  @HiveField(8)
  String? kundensSagsref;

  @HiveField(9)
  String? beskrivelse;

  @HiveField(10)
  String status;

  @HiveField(11)
  bool aktiv;

  @HiveField(12)
  bool? arkiveret;

  @HiveField(13)
  String? arkiveretDato;

  @HiveField(14)
  String? sagType; // 'udtørring', 'varme', 'begge'

  @HiveField(15)
  String? region; // 'fyn', 'jylland', 'sjælland'

  @HiveField(16)
  String oprettetAf;

  @HiveField(17)
  String oprettetDato;

  @HiveField(18)
  String opdateretDato;

  @HiveField(19)
  String? createdAt;

  @HiveField(20)
  String? updatedAt;

  Sag({
    required this.id,
    required this.sagsnr,
    required this.adresse,
    required this.byggeleder,
    this.byggelederEmail,
    this.byggelederTlf,
    this.bygherre,
    this.cvrNr,
    this.kundensSagsref,
    this.beskrivelse,
    required this.status,
    required this.aktiv,
    this.arkiveret,
    this.arkiveretDato,
    this.sagType,
    this.region,
    required this.oprettetAf,
    required this.oprettetDato,
    required this.opdateretDato,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sagsnr': sagsnr,
        'adresse': adresse,
        'byggeleder': byggeleder,
        'byggelederEmail': byggelederEmail,
        'byggelederTlf': byggelederTlf,
        'bygherre': bygherre,
        'cvrNr': cvrNr,
        'kundensSagsref': kundensSagsref,
        'beskrivelse': beskrivelse,
        'status': status,
        'aktiv': aktiv,
        'arkiveret': arkiveret,
        'arkiveretDato': arkiveretDato,
        'sagType': sagType,
        'region': region,
        'oprettetAf': oprettetAf,
        'oprettetDato': oprettetDato,
        'opdateretDato': opdateretDato,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory Sag.fromJson(Map<String, dynamic> json) => Sag(
        id: json['id'] as String,
        sagsnr: json['sagsnr'] as String,
        adresse: json['adresse'] as String,
        byggeleder: json['byggeleder'] as String,
        byggelederEmail: json['byggelederEmail'] as String?,
        byggelederTlf: json['byggelederTlf'] as String?,
        bygherre: json['bygherre'] as String?,
        cvrNr: json['cvrNr'] as String?,
        kundensSagsref: json['kundensSagsref'] as String?,
        beskrivelse: json['beskrivelse'] as String?,
        status: json['status'] as String,
        aktiv: json['aktiv'] as bool,
        arkiveret: json['arkiveret'] as bool?,
        arkiveretDato: json['arkiveretDato'] as String?,
        sagType: json['sagType'] as String?,
        region: json['region'] as String?,
        oprettetAf: json['oprettetAf'] as String,
        oprettetDato: json['oprettetDato'] as String,
        opdateretDato: json['opdateretDato'] as String,
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
      );
}
