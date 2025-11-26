/// Constants for roles and features in the SKA-DAN app
class AppRoles {
  static const String admin = 'admin';
  static const String tekniker = 'tekniker';
  static const String bogholder = 'bogholder';

  static const List<String> all = [admin, tekniker, bogholder];

  static const Map<String, String> labels = {
    admin: 'Admin',
    tekniker: 'Tekniker',
    bogholder: 'Bogholder',
  };
}

class AppFeatures {
  // Core features
  static const String createCases = 'ny_sag';
  static const String timeTracking = 'timer';
  static const String equipmentManagement = 'udstyr';
  static const String cableLogging = 'kabler_slanger';
  static const String blockManagement = 'blokke';
  static const String nfcScanning = 'nfc';

  // Financial features
  static const String invoicing = 'faktura';
  static const String profitability = 'rentabilitet';

  // Admin features
  static const String userManagement = 'brugeradministration';
  static const String settings = 'indstillinger';

  static const List<String> all = [
    createCases,
    timeTracking,
    equipmentManagement,
    cableLogging,
    blockManagement,
    nfcScanning,
    invoicing,
    profitability,
    userManagement,
    settings,
  ];

  static const Map<String, String> labels = {
    createCases: 'Opret sager',
    timeTracking: 'Tidsregistrering',
    equipmentManagement: 'Udstyrshåndtering',
    cableLogging: 'Kabler & Slanger',
    blockManagement: 'Blok-administration',
    nfcScanning: 'NFC-scanning',
    invoicing: 'Fakturering',
    profitability: 'Rentabilitet',
    userManagement: 'Brugeradministration',
    settings: 'Indstillinger',
  };

  static const Map<String, String> descriptions = {
    createCases: 'Mulighed for at oprette nye sager',
    timeTracking: 'Mulighed for at registrere timer',
    equipmentManagement: 'Mulighed for at håndtere udstyr',
    cableLogging: 'Mulighed for at logge kabler og slanger',
    blockManagement: 'Mulighed for at administrere blokke',
    nfcScanning: 'Mulighed for at scanne NFC-tags',
    invoicing: 'Mulighed for at se faktureringsdata',
    profitability: 'Mulighed for at se rentabilitet',
    userManagement: 'Mulighed for at administrere brugere',
    settings: 'Mulighed for at ændre indstillinger',
  };

  /// Get default features for a role
  static List<String> getDefaultFeaturesForRole(String role) {
    switch (role) {
      case AppRoles.admin:
        return all; // Admin has all features
      case AppRoles.bogholder:
        return [
          invoicing,
          profitability,
          timeTracking,
        ];
      case AppRoles.tekniker:
      default:
        return [
          createCases,
          timeTracking,
          equipmentManagement,
          cableLogging,
          blockManagement,
          nfcScanning,
        ];
    }
  }
}
