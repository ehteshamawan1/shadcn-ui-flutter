# SKA-DAN Flutter App

## 📱 Om Projektet

Dette er en Flutter konvertering af SKA-DAN PWA (Progressive Web App) - et sagsstyringssystem for tekniker-team. Appen håndterer sager, udstyr, timer registrering, NFC scanning og meget mere.

## ✅ Hvad er Konverteret

### Core Funktionalitet
- ✅ **Flutter projekt struktur** - Komplet project setup med alle dependencies
- ✅ **Authentication Service** - PIN-baseret login system med session management
- ✅ **Database Service** - Hive-baseret lokal database med offline support
- ✅ **Theme Provider** - Dark/Light mode support med Material 3 design
- ✅ **Login Screen** - Komplet login skærm med PIN numpad
- ✅ **Dashboard Screen** - Hovedskærm med statistik og quick actions
- ✅ **Navigation/Routing** - Komplet routing system med authentication guards

### Data Models
- ✅ **User Model** - Bruger data med roller (tekniker, admin, bogholder)
- ✅ **Sag Model** - Sagsstyring med alle felter
- ✅ **Affugter Model** - Affugter/udstyr håndtering
- ✅ **Equipment Log Model** - Udstyr logning
- ✅ **Timer Log Model** - Timer registrering

### Services
- ✅ **AuthService** - Authentication og session management
- ✅ **DatabaseService** - Hive database operations med sample data
- ✅ **NFCService** - NFC scanning support (skeleton)

### UI Components
- ✅ **Theme Provider** - Komplet dark/light theme support
- ✅ **Material 3 Design** - Moderne UI med custom color schemes
- ✅ **Responsive Layout** - Tilpasset til forskellige skærmstørrelser

## 🚧 Hvad Mangler (TODO)

### Screens der skal oprettes:
- ⏳ **Sager Screen** - Liste og søgning af alle sager
- ⏳ **SagDetaljer Screen** - Detaljeret visning af en sag
- ⏳ **NySag Screen** - Opret ny sag formular
- ⏳ **Affugtere Screen** - Affugter lageroversigt
- ⏳ **UdstyrsOversigt Screen** - Samlet udstyrsoversigt
- ⏳ **TimerRegistrering Screen** - Timer registrering for tekniker
- ⏳ **NFCScanner Screen** - NFC scanning interface

### Additional Features:
- ⏳ **Supabase Integration** - Cloud sync funktionalitet
- ⏳ **Offline Sync Manager** - Bidirectional synkronisering
- ⏳ **Notification System** - Push notifications
- ⏳ **PDF Generation** - Faktura og rapport generering
- ⏳ **Admin Panel** - Administration af brugere og indstillinger

## 🚀 Sådan Kører Du Appen

### Forudsætninger
- Flutter SDK (version 3.0.0 eller nyere)
- Dart SDK
- Android Studio / VS Code med Flutter plugin
- En Android/iOS emulator eller fysisk enhed

### Installation

1. **Clone projektet:**
```bash
cd c:\workspace\project\ska-dan\ska_dan_flutter
```

2. **Installer dependencies:**
```bash
flutter pub get
```

3. **Generer Hive adapters (hvis nødvendigt):**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **Kør appen:**
```bash
flutter run
```

## 📦 Dependencies

### Production Dependencies:
- **provider** (^6.1.2) - State management
- **hive** (^2.2.3) & **hive_flutter** (^1.1.0) - Lokal database
- **supabase_flutter** (^2.10.0) - Cloud backend
- **nfc_manager** (^3.5.0) - NFC scanning
- **google_fonts** (^6.2.1) - Custom fonts
- **intl** (^0.19.0) - Internationalisering
- **uuid** (^4.5.1) - Unikke ID'er
- **shared_preferences** (^2.3.3) - Settings storage
- **connectivity_plus** (^6.1.0) - Network status
- **pdf** (^3.11.1) & **printing** (^5.13.4) - PDF generering
- **flutter_local_notifications** (^18.0.1) - Notifikationer

### Development Dependencies:
- **flutter_lints** (^5.0.0) - Code linting
- **hive_generator** (^2.0.1) - Generer Hive adapters
- **build_runner** (^2.4.13) - Build tools

## 🗂️ Projekt Struktur

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user.dart            # Bruger model
│   ├── sag.dart             # Sag model
│   ├── affugter.dart        # Affugter model
│   ├── equipment_log.dart   # Udstyr log
│   └── timer_log.dart       # Timer log
├── services/                 # Business logic
│   ├── auth_service.dart    # Authentication
│   ├── database_service.dart # Database operations
│   └── nfc_service.dart     # NFC operations
├── providers/                # State management
│   └── theme_provider.dart  # Theme provider
├── screens/                  # UI screens
│   ├── login_screen.dart    # Login skærm
│   └── dashboard_screen.dart # Dashboard
├── widgets/                  # Reusable widgets
├── utils/                    # Helper functions
└── config/                   # Configuration
```

## 🔐 Login Information (Test Brugere)

Appen har følgende test brugere:

1. **Rasmus** (Tekniker)
   - PIN: `1234`

2. **Stefan** (Tekniker)
   - PIN: `1235`

3. **Christian** (Tekniker)
   - PIN: `1236`

4. **Tanja** (Admin)
   - PIN: `0000`

## 🎨 Theme Support

Appen understøtter både Light og Dark mode:
- Automatisk gemmes i SharedPreferences
- Kan skiftes dynamisk i appen
- Material 3 design system
- Custom color schemes baseret på SKA-DAN branding

## 🗄️ Database

Appen bruger **Hive** til lokal offline storage:
- Lightning-fast NoSQL database
- Type-safe med code generation
- Automatisk persistence
- Support for custom objects

### Sample Data
Ved første opstart initialiseres appen med:
- 4 test brugere
- 2 test sager
- 2 test affugtere

## 📱 Platforme

Appen er konfigureret til at køre på:
- ✅ Android
- ✅ iOS
- ✅ Windows
- ✅ macOS
- ✅ Linux
- ✅ Web

## 🔧 Udvikling

### Generer Hive Adapters
Når du ændrer models med `@HiveType` annotations:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Watch Mode (automatisk regenerering)
```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Ryd Build Cache
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

## 📝 Næste Skridt

For at færdiggøre konverteringen:

1. **Opret manglende screens:**
   - Sager (case list)
   - SagDetaljer (case details)
   - NySag (create case)
   - Affugtere (equipment inventory)
   - UdstyrsOversigt (equipment overview)
   - TimerRegistrering (time tracking)
   - NFCScanner (NFC scanning)

2. **Implementer Supabase sync:**
   - Konfigurer Supabase client
   - Implementer real-time listeners
   - Håndter konflikt resolution

3. **Tilføj avancerede features:**
   - PDF faktura generering
   - Push notifications
   - Offline sync queue
   - Admin panel

## 🐛 Debugging

### Common Issues:

**Problem:** Build errors efter `pub get`
**Løsning:** Kør `flutter clean` og derefter `flutter pub get`

**Problem:** Hive TypeAdapter errors
**Løsning:** Kør `flutter pub run build_runner build --delete-conflicting-outputs`

**Problem:** "MissingPluginException"
**Løsning:** Stop appen, kør `flutter clean`, og start igen

## 📄 Licens

Dette projekt er udviklet til SKA-DAN.

## 👥 Contributors

- Initial React PWA: Original team
- Flutter Conversion: Claude Code Assistant

---

**Version:** 2.2.0
**Build Date:** 2025-10-25
**Features:** Bidirectional Sync, Real-time Updates, Offline Support
## Offline sync (ny)

- Alle lokale �ndringer (sager, affugtere, udstyr- og timer-logs, brugere) l�gges i en lokal Hive-k�.
- `SyncService` overv�ger netv�rk og fors�ger automatisk at sync'e k�en, n�r der er forbindelse.
- Aktiv�r cloud-sync ved at give Supabase credentials som `--dart-define`:
  ```bash
  flutter run --dart-define SUPABASE_URL=https://din-projekt-id.supabase.co ^
              --dart-define SUPABASE_ANON_KEY=public-anon-key
  ```
  Hvis URL/key ikke er sat, bliver k�en liggende lokalt (ingen data forlader enheden).
- Tabeller der sync�es: `sager`, `affugtere`, `equipment_logs`, `timer_logs`, `users` (upsert/delete p� feltet `id`).
