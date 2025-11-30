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
  // Core sag features
  static const String viewCases = 'sager';           // View sager list
  static const String createCases = 'ny_sag';        // Create new sager
  static const String editCases = 'rediger_sag';     // Edit existing sager

  // Equipment features
  static const String equipmentManagement = 'udstyr';
  static const String nfcScanning = 'nfc';
  static const String cableLogging = 'kabler_slanger';
  static const String blockManagement = 'blokke';

  // Time tracking
  static const String timeTracking = 'timer';

  // Communication
  static const String messages = 'beskeder';

  // Financial features
  static const String invoicing = 'faktura';
  static const String profitability = 'rentabilitet';

  // Admin features
  static const String userManagement = 'brugeradministration';
  static const String settings = 'indstillinger';
  static const String backup = 'backup';
  static const String activityLog = 'aktivitetslog';
  static const String dropdownSettings = 'dropdown_indstillinger';

  static const List<String> all = [
    viewCases,
    createCases,
    editCases,
    equipmentManagement,
    nfcScanning,
    cableLogging,
    blockManagement,
    timeTracking,
    messages,
    invoicing,
    profitability,
    userManagement,
    settings,
    backup,
    activityLog,
    dropdownSettings,
  ];

  static const Map<String, String> labels = {
    viewCases: 'Se sager',
    createCases: 'Opret sager',
    editCases: 'Rediger sager',
    equipmentManagement: 'Udstyrshåndtering',
    nfcScanning: 'NFC-scanning',
    cableLogging: 'Kabler & Slanger',
    blockManagement: 'Blok-administration',
    timeTracking: 'Tidsregistrering',
    messages: 'Beskeder',
    invoicing: 'Fakturering',
    profitability: 'Rentabilitet',
    userManagement: 'Brugeradministration',
    settings: 'Indstillinger',
    backup: 'Backup & Gendannelse',
    activityLog: 'Aktivitetslog',
    dropdownSettings: 'Dropdown-indstillinger',
  };

  static const Map<String, String> descriptions = {
    viewCases: 'Mulighed for at se sager',
    createCases: 'Mulighed for at oprette nye sager',
    editCases: 'Mulighed for at redigere eksisterende sager',
    equipmentManagement: 'Mulighed for at håndtere udstyr og affugtere',
    nfcScanning: 'Mulighed for at scanne NFC-tags',
    cableLogging: 'Mulighed for at logge kabler og slanger',
    blockManagement: 'Mulighed for at administrere blokke',
    timeTracking: 'Mulighed for at registrere timer',
    messages: 'Mulighed for at sende og se beskeder',
    invoicing: 'Mulighed for at se og oprette fakturaer',
    profitability: 'Mulighed for at se rentabilitet',
    userManagement: 'Mulighed for at administrere brugere',
    settings: 'Mulighed for at ændre indstillinger',
    backup: 'Mulighed for at lave backup og gendannelse',
    activityLog: 'Mulighed for at se aktivitetslog',
    dropdownSettings: 'Mulighed for at administrere dropdown-værdier',
  };

  /// Get default features for a role
  static List<String> getDefaultFeaturesForRole(String role) {
    switch (role) {
      case AppRoles.admin:
        return all; // Admin has all features
      case AppRoles.bogholder:
        return [
          viewCases,
          invoicing,
          profitability,
          timeTracking,
          activityLog,
        ];
      case AppRoles.tekniker:
      default:
        return [
          viewCases,
          createCases,
          editCases,
          timeTracking,
          equipmentManagement,
          cableLogging,
          blockManagement,
          nfcScanning,
          messages,
        ];
    }
  }
}
