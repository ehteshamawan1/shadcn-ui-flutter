import 'nfc_service_base.dart';

/// Web stub for NFC service - NFC not supported on web platform
class NFCService {
  static final NFCService _instance = NFCService._internal();
  factory NFCService() => _instance;
  NFCService._internal();

  final bool _isScanning = false;
  final bool _isWriting = false;

  // Check if NFC is supported
  Future<bool> isSupported() async {
    print('⚠️  NFC is not supported on web platform');
    return false;
  }

  // Start NFC scanning
  Future<void> startScanning({
    required Function(NFCData) onRead,
    Function(String)? onError,
  }) async {
    onError?.call('NFC scanning er ikke tilgængelig på web platform');
    return;
  }

  // Stop NFC scanning
  Future<void> stopScanning() async {
    // No-op on web
  }

  // Write equipment data to NFC tag
  Future<bool> writeEquipmentToTag(NFCEquipmentData equipmentData) async {
    throw Exception('NFC skrivning er ikke tilgængelig på web platform');
  }

  // Check if currently scanning
  bool get isScanning => _isScanning;

  // Check if currently writing
  bool get isWriting => _isWriting;
}
