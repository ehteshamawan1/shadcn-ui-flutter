import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/sag.dart';

/// Service til integration med e-conomic API
/// Dokumentation: https://restdocs.e-conomic.com/
class EconomicService {
  // e-conomic API configuration
  static const String _baseUrl = 'https://restapi.e-conomic.com';

  // Disse skal sættes i environment variables eller configuration
  String? _appSecretToken;
  String? _agreementGrantToken;

  /// Sæt API credentials
  void setCredentials({
    required String appSecretToken,
    required String agreementGrantToken,
  }) {
    _appSecretToken = appSecretToken;
    _agreementGrantToken = agreementGrantToken;
  }

  /// Check om credentials er sat
  bool get hasCredentials =>
      _appSecretToken != null && _agreementGrantToken != null;

  /// Get HTTP headers for e-conomic API
  Map<String, String> _getHeaders() {
    if (!hasCredentials) {
      throw Exception('e-conomic credentials ikke sat. Kald setCredentials() først.');
    }

    return {
      'Content-Type': 'application/json',
      'X-AppSecretToken': _appSecretToken!,
      'X-AgreementGrantToken': _agreementGrantToken!,
    };
  }

  /// Opret draft invoice i e-conomic
  Future<Map<String, dynamic>> createDraftInvoice({
    required Sag sag,
    required List<Map<String, dynamic>> lines,
    String? notes,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/invoices/drafts');

      // Find eller opret kunde
      final customer = await _getOrCreateCustomer(sag);

      final body = {
        'date': DateTime.now().toIso8601String().split('T')[0],
        'customer': {
          'customerNumber': customer['customerNumber'],
        },
        'recipient': {
          'name': sag.byggeleder,
          'address': sag.adresse,
          'email': sag.byggelederEmail ?? '',
        },
        'layout': {
          'layoutNumber': 1, // Default layout
        },
        'lines': lines,
        'notes': {
          'heading': 'Sagsnr: ${sag.sagsnr}',
          'textLine1': notes ?? sag.beskrivelse ?? '',
        },
        'references': {
          'other': sag.sagsnr,
        },
      };

      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Fejl ved oprettelse af faktura: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Fejl i createDraftInvoice: $e');
      rethrow;
    }
  }

  /// Hent eller opret kunde i e-conomic
  Future<Map<String, dynamic>> _getOrCreateCustomer(Sag sag) async {
    try {
      // Prøv at finde eksisterende kunde via email
      if (sag.byggelederEmail != null && sag.byggelederEmail!.isNotEmpty) {
        final existingCustomer = await _findCustomerByEmail(sag.byggelederEmail!);
        if (existingCustomer != null) {
          return existingCustomer;
        }
      }

      // Opret ny kunde hvis ikke fundet
      return await _createCustomer(sag);
    } catch (e) {
      debugPrint('Fejl i _getOrCreateCustomer: $e');
      rethrow;
    }
  }

  /// Find kunde via email
  Future<Map<String, dynamic>?> _findCustomerByEmail(String email) async {
    try {
      final url = Uri.parse('$_baseUrl/customers?filter=email\$eq:$email');

      final response = await http.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final customers = data['collection'] as List?;

        if (customers != null && customers.isNotEmpty) {
          return customers.first as Map<String, dynamic>;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Fejl i _findCustomerByEmail: $e');
      return null;
    }
  }

  /// Opret ny kunde i e-conomic
  Future<Map<String, dynamic>> _createCustomer(Sag sag) async {
    try {
      final url = Uri.parse('$_baseUrl/customers');

      final body = {
        'name': sag.byggeleder,
        'email': sag.byggelederEmail ?? '',
        'telephoneAndFaxNumber': sag.byggelederTlf ?? '',
        'address': sag.adresse,
        'currency': 'DKK',
        'paymentTerms': {
          'paymentTermsNumber': 1, // Default payment terms
        },
        'customerGroup': {
          'customerGroupNumber': 1, // Default customer group
        },
        'vatZone': {
          'vatZoneNumber': 1, // Denmark
        },
      };

      if (sag.cvrNr != null && sag.cvrNr!.isNotEmpty) {
        body['corporateIdentificationNumber'] = sag.cvrNr!;
      }

      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Fejl ved oprettelse af kunde: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Fejl i _createCustomer: $e');
      rethrow;
    }
  }

  /// Book (send) en draft invoice
  Future<Map<String, dynamic>> bookDraftInvoice(int draftInvoiceNumber) async {
    try {
      final url = Uri.parse('$_baseUrl/invoices/drafts/$draftInvoiceNumber/book');

      final response = await http.post(
        url,
        headers: _getHeaders(),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Fejl ved booking af faktura: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Fejl i bookDraftInvoice: $e');
      rethrow;
    }
  }

  /// Eksporter valgte sager til e-conomic som draft invoices
  Future<List<Map<String, dynamic>>> exportSagerToEconomic(
    List<Sag> sager, {
    required Function(Sag sag) getInvoiceLines,
    String? notes,
  }) async {
    if (!hasCredentials) {
      throw Exception('e-conomic credentials ikke sat');
    }

    final results = <Map<String, dynamic>>[];

    for (final sag in sager) {
      try {
        final lines = getInvoiceLines(sag);
        final invoice = await createDraftInvoice(
          sag: sag,
          lines: lines as List<Map<String, dynamic>>,
          notes: notes,
        );

        results.add({
          'sagsnr': sag.sagsnr,
          'success': true,
          'invoice': invoice,
        });
      } catch (e) {
        results.add({
          'sagsnr': sag.sagsnr,
          'success': false,
          'error': e.toString(),
        });
      }
    }

    return results;
  }

  /// Hent produkter fra e-conomic (til faktura linjer)
  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final url = Uri.parse('$_baseUrl/products');

      final response = await http.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['collection'] as List).cast<Map<String, dynamic>>();
      } else {
        throw Exception(
          'Fejl ved hentning af produkter: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Fejl i getProducts: $e');
      rethrow;
    }
  }
}
