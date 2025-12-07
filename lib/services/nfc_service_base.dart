// Shared NFC data models - used on both mobile and web
class NFCData {
  final String id; // PERMANENT equipment number (e.g., 2-2345)
  final String type;
  final String? navn;
  final String? placering;
  final Map<String, dynamic>? data;
  final bool isCompatible;
  final List<String>? compatibilityIssues;
  final String? sagId;
  final String? status; // 'hjemme', 'udlejet', 'defekt'

  NFCData({
    required this.id,
    required this.type,
    this.navn,
    this.placering,
    this.data,
    this.isCompatible = true,
    this.compatibilityIssues,
    this.sagId,
    this.status,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'navn': navn,
        'placering': placering,
        'data': data,
        'sagId': sagId,
        'status': status,
      };

  factory NFCData.fromJson(Map<String, dynamic> json) {
    // Handle both old format ('equipment') and new compact format ('eq')
    String type = json['type'] as String? ?? 'equipment';
    if (type == 'eq') type = 'equipment';

    // Handle compact data format with short keys
    Map<String, dynamic>? data = json['data'] as Map<String, dynamic>?;
    if (data != null) {
      // Expand short keys to full keys for compatibility
      if (data.containsKey('m') && !data.containsKey('maerke')) {
        data = Map<String, dynamic>.from(data);
        data['maerke'] = data['m'];
      }
      if (data.containsKey('o') && !data.containsKey('model')) {
        data = Map<String, dynamic>.from(data);
        data['model'] = data['o'];
      }
    }

    return NFCData(
      id: json['id'] as String? ?? '',
      type: type,
      navn: json['navn'] as String?,
      placering: json['placering'] as String?,
      data: data,
      sagId: json['sagId'] as String?,
      status: json['status'] as String?,
    );
  }
}

class NFCEquipmentData {
  final String id; // PERMANENT ID
  final String navn;
  final String type;
  final String? maerke;
  final String? model;
  final String? serie;
  final String? regNr;
  final String? sagId;
  final String? status;

  NFCEquipmentData({
    required this.id,
    required this.navn,
    required this.type,
    this.maerke,
    this.model,
    this.serie,
    this.regNr,
    this.sagId,
    this.status,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'navn': navn,
        'type': type,
        'mærke': maerke,
        'model': model,
        'serie': serie,
        'regNr': regNr,
        'sagId': sagId,
        'status': status,
      };

  factory NFCEquipmentData.fromJson(Map<String, dynamic> json) =>
      NFCEquipmentData(
        id: json['id'] as String,
        navn: json['navn'] as String,
        type: json['type'] as String,
        maerke: json['mærke'] as String?,
        model: json['model'] as String?,
        serie: json['serie'] as String?,
        regNr: json['regNr'] as String?,
        sagId: json['sagId'] as String?,
        status: json['status'] as String?,
      );
}
