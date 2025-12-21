import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import '../models/sag.dart';
import 'database_service.dart';

// Conditional import: uses stub on mobile, web implementation on web
import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart' as download_helper;

class ExportService {
  final DatabaseService _db = DatabaseService();

  /// Eksporter sager til CSV
  String exportSagerToCSV(List<Sag> sager) {
    List<List<dynamic>> rows = [];

    // Header row
    rows.add([
      'Sagsnr',
      'Adresse',
      'Byggeleder',
      'Email',
      'Telefon',
      'Status',
      'Type',
      'Region',
      'Oprettet dato',
      'Opdateret dato',
      'Oprettet af',
    ]);

    // Data rows
    for (var sag in sager) {
      rows.add([
        sag.sagsnr,
        sag.adresse,
        sag.byggeleder,
        sag.byggelederEmail ?? '',
        sag.byggelederTlf ?? '',
        sag.status,
        sag.sagType ?? '',
        sag.region ?? '',
        sag.oprettetDato,
        sag.opdateretDato,
        sag.oprettetAf,
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Hent aktive sager
  List<Sag> getAktiveSager() {
    return _db.getAllSager().where((sag) => sag.aktiv).toList();
  }

  /// Hent afsluttede sager
  List<Sag> getAfsluttedeSager() {
    return _db.getAllSager().where((sag) => !sag.aktiv).toList();
  }

  /// Eksporter aktive sager til CSV
  String exportAktiveSagerToCSV() {
    final aktiveSager = getAktiveSager();
    return exportSagerToCSV(aktiveSager);
  }

  /// Eksporter afsluttede sager til CSV
  String exportAfsluttedeSagerToCSV() {
    final afsluttedeSager = getAfsluttedeSager();
    return exportSagerToCSV(afsluttedeSager);
  }

  /// Eksporter alle sager til CSV
  String exportAlleSagerToCSV() {
    final alleSager = _db.getAllSager();
    return exportSagerToCSV(alleSager);
  }

  /// Download CSV fil (cross-platform)
  Future<void> downloadCSVFile(String csvContent, String filename) async {
    try {
      await download_helper.downloadFile(
        content: csvContent,
        filename: filename,
        mimeType: 'text/csv',
      );
      debugPrint('CSV file downloaded: $filename');
    } catch (e) {
      debugPrint('Error downloading CSV: $e');
      rethrow;
    }
  }

  /// Download JSON fil (cross-platform)
  Future<void> downloadJSONFile(String jsonContent, String filename) async {
    try {
      await download_helper.downloadFile(
        content: jsonContent,
        filename: filename,
        mimeType: 'application/json',
      );
      debugPrint('JSON file downloaded: $filename');
    } catch (e) {
      debugPrint('Error downloading JSON: $e');
      rethrow;
    }
  }
}
