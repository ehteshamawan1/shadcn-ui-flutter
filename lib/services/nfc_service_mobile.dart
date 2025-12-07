import 'dart:convert';
import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';
import 'nfc_service_base.dart';

class NFCService {
  static final NFCService _instance = NFCService._internal();
  factory NFCService() => _instance;
  NFCService._internal();

  bool _isScanning = false;
  bool _isWriting = false;

  // Check if NFC is supported
  Future<bool> isSupported() async {
    return await NfcManager.instance.isAvailable();
  }

  // Start NFC scanning
  Future<void> startScanning({
    required Function(NFCData) onRead,
    Function(String)? onError,
  }) async {
    if (_isScanning) {
      onError?.call('NFC scanning er allerede aktiv');
      return;
    }

    try {
      _isScanning = true;

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final ndefMessage = tag.data['ndef'];
            if (ndefMessage != null) {
              final records = ndefMessage['cachedMessage']['records'];

              if (records != null && records.isNotEmpty) {
                for (var record in records) {
                  try {
                    final payload = record['payload'] as List<int>?;
                    if (payload != null) {
                      // Decode NDEF payload (skip language code byte)
                      final text = utf8.decode(payload.sublist(3));
                      print('NFC Data: $text');

                      // Try to parse as JSON
                      try {
                        final jsonData = jsonDecode(text) as Map<String, dynamic>;
                        final nfcData = NFCData.fromJson(jsonData);
                        onRead(nfcData);
                      } catch (e) {
                        // If not JSON, try to extract equipment number
                        final affugterNr = _extractAffugterNumber(text);
                        if (affugterNr != null) {
                          onRead(NFCData(
                            id: affugterNr,
                            type: 'equipment',
                            navn: 'Affugter $affugterNr',
                            data: {'rawText': text, 'parsedFromText': true},
                          ));
                        } else {
                          // Blank tag
                          onRead(NFCData(
                            id: '',
                            type: 'equipment',
                            data: {'blankTag': true, 'firstTimeSetup': true},
                          ));
                        }
                      }
                      break;
                    }
                  } catch (e) {
                    print('Error parsing record: $e');
                  }
                }
              } else {
                // No records - blank tag
                onRead(NFCData(
                  id: '',
                  type: 'equipment',
                  data: {'blankTag': true, 'firstTimeSetup': true},
                ));
              }
            } else {
              // No NDEF data - blank tag
              onRead(NFCData(
                id: '',
                type: 'equipment',
                data: {'blankTag': true, 'firstTimeSetup': true},
              ));
            }

            // Stop session after successful read
            await NfcManager.instance.stopSession();
            _isScanning = false;
          } catch (e) {
            print('Error processing NFC tag: $e');
            // Stop session and reset scanning flag on error
            try {
              await NfcManager.instance.stopSession(errorMessage: 'Fejl ved behandling af data');
            } catch (_) {
              // Session may already be stopped
            }
            _isScanning = false;
            onError?.call('Fejl ved behandling af NFC data');
          }
        },
      );
    } catch (e) {
      _isScanning = false;
      print('NFC scan error: $e');
      onError?.call('Kunne ikke starte NFC scanning: $e');
    }
  }

  // Stop NFC scanning
  Future<void> stopScanning() async {
    if (_isScanning) {
      await NfcManager.instance.stopSession();
      _isScanning = false;
    }
  }

  // Write equipment data to NFC tag
  Future<void> writeEquipmentToTag(NFCEquipmentData equipmentData) async {
    if (_isWriting) {
      throw Exception('NFC skrivning er allerede i gang');
    }

    try {
      _isWriting = true;

      final nfcData = NFCData(
        id: equipmentData.id, // PERMANENT ID
        type: 'equipment',
        navn: equipmentData.navn,
        sagId: equipmentData.sagId,
        status: equipmentData.status ?? 'hjemme',
        data: {
          'permanentId': equipmentData.id,
          'maerke': equipmentData.maerke,
          'model': equipmentData.model,
          'serie': equipmentData.serie,
          'regNr': equipmentData.regNr,
          'type': equipmentData.type,
          'currentSagId': equipmentData.sagId,
          'currentStatus': equipmentData.status,
          'lastUpdated': DateTime.now().toIso8601String(),
          'version': '2.0',
        },
      );

      bool writeCompleted = false;
      String? writeError;

      print('NFC: Starting write session for ID: ${equipmentData.id}');

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            print('NFC: Tag discovered, checking NDEF support...');
            final ndef = Ndef.from(tag);

            if (ndef == null) {
              print('NFC Error: Tag does not support NDEF');
              throw Exception('NFC tag understøtter ikke NDEF format');
            }

            if (!ndef.isWritable) {
              print('NFC Error: Tag is not writable (isWritable=false)');
              throw Exception('NFC tag er skrivebeskyttet');
            }

            // Create NDEF message
            final jsonString = jsonEncode(nfcData.toJson());
            print('NFC: JSON data length: ${jsonString.length} bytes');

            final languageCodeBytes = [0x02, 0x65, 0x6e]; // "en"
            final textBytes = utf8.encode(jsonString);
            final payload = [...languageCodeBytes, ...textBytes];

            final ndefMessage = NdefMessage([
              NdefRecord(
                typeNameFormat: NdefTypeNameFormat.nfcWellknown,
                type: Uint8List.fromList([0x54]), // "T" for Text
                identifier: Uint8List(0),
                payload: Uint8List.fromList(payload),
              ),
            ]);

            // Check size before writing
            final messageSize = ndefMessage.byteLength;
            final maxSize = ndef.maxSize;
            print('NFC: Message size: $messageSize bytes, Tag capacity: $maxSize bytes');

            if (messageSize > maxSize) {
              throw Exception('Data er for stor til NFC tag ($messageSize > $maxSize bytes)');
            }

            // Write to tag with detailed error handling
            print('NFC: Starting write operation...');
            try {
              await ndef.write(ndefMessage);
              print('NFC: Write operation completed successfully');
            } catch (writeEx) {
              print('NFC: Write failed with error: $writeEx');
              print('NFC: Error type: ${writeEx.runtimeType}');
              // Convert io_exception to user-friendly message
              if (writeEx.toString().contains('io_exception')) {
                throw Exception('NFC kommunikationsfejl - hold telefonen stille på tagget i mindst 2 sekunder');
              }
              rethrow;
            }

            writeCompleted = true;
            print('NFC: Stopping session...');
            await NfcManager.instance.stopSession();
            print('NFC: Session stopped successfully');
            _isWriting = false;
          } catch (e) {
            print('NFC write error in callback: $e');
            writeError = e.toString();
            _isWriting = false;
            try {
              await NfcManager.instance.stopSession(errorMessage: e.toString());
            } catch (stopErr) {
              print('NFC: Error stopping session: $stopErr');
            }
          }
        },
      );

      // Wait for write with timeout
      int timeoutCounter = 0;
      while (!writeCompleted && timeoutCounter < 30 && writeError == null) {
        await Future.delayed(const Duration(milliseconds: 500));
        timeoutCounter++;
      }

      if (writeError != null) {
        throw Exception(writeError);
      }

      if (!writeCompleted) {
        _isWriting = false;
        throw Exception('Timeout: Hold telefonen tæt på NFC tagget i mindst 2 sekunder');
      }
    } catch (e) {
      _isWriting = false;
      print('NFC write outer error: $e');
      // Clean up the error message
      String errorMsg = e.toString().replaceAll('Exception:', '').trim();
      throw Exception(errorMsg);
    }
  }

  // Extract affugter number from raw text
  String? _extractAffugterNumber(String text) {
    // Look for patterns like 2-2345, 1-0123, etc.
    final patterns = [
      RegExp(r'(\d+)-(\d+)'), // 2-2345
      RegExp(r'AF[-:]?(\d+)'), // AF-090, AF:090
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        if (match.groupCount >= 2) {
          // Has machine type and serial
          return '${match.group(1)}-${match.group(2)}';
        } else if (match.groupCount >= 1) {
          // Only serial, assume machine type 2
          return '2-${match.group(1)}';
        }
      }
    }

    return null;
  }

  // Check if currently scanning
  bool get isScanning => _isScanning;

  // Check if currently writing
  bool get isWriting => _isWriting;
}
