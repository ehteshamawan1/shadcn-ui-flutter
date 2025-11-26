// Export shared NFC data models
export 'nfc_service_base.dart';

// Platform-specific NFC service exports
export 'nfc_service_mobile.dart'
    if (dart.library.io) 'nfc_service_mobile.dart'
    if (dart.library.html) 'nfc_service_web.dart';
