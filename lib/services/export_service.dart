import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show AnchorElement;
import '../models/sag.dart';
import 'database_service.dart';

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

  /// Download CSV fil (web platform)
  void downloadCSVFile(String csvContent, String filename) {
    if (kIsWeb) {
      // For web: Create download link
      final bytes = utf8.encode(csvContent);
      final base64str = base64Encode(bytes);
      html.AnchorElement(href: 'data:text/csv;charset=utf-8;base64,$base64str')
        ..setAttribute('download', filename)
        ..click();
    } else {
      // For mobile/desktop: Will need to use path_provider and file system
      debugPrint('Mobile CSV download not implemented yet');
      debugPrint('CSV Content:\n$csvContent');
    }
  }
}
