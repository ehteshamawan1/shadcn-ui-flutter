import 'dart:async';
import 'dart:convert';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';
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
            print('NFC Read: Tag discovered, data keys: ${tag.data.keys.toList()}');

            // Use Ndef class for safe access
            final ndef = Ndef.from(tag);

            if (ndef != null && ndef.cachedMessage != null && ndef.cachedMessage!.records.isNotEmpty) {
              // Tag has NDEF data
              final record = ndef.cachedMessage!.records.first;
              final payload = record.payload;

              if (payload.isNotEmpty) {
                // Decode NDEF text payload - first byte is language code length
                final langCodeLen = payload[0];
                final text = utf8.decode(payload.sublist(1 + langCodeLen));
                print('NFC Read: Data: $text');

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
                    // Unknown text format
                    onRead(NFCData(
                      id: '',
                      type: 'equipment',
                      data: {'rawText': text, 'unknownFormat': true},
                    ));
                  }
                }
              } else {
                // Empty payload - blank tag
                print('NFC Read: Empty payload');
                onRead(NFCData(
                  id: '',
                  type: 'equipment',
                  data: {'blankTag': true, 'firstTimeSetup': true},
                ));
              }
            } else {
              // No NDEF data or no cached message - blank tag
              print('NFC Read: No NDEF data or empty tag');
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
            onError?.call('Fejl ved behandling af NFC data: $e');
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
  // Returns true if write was successful
  Future<bool> writeEquipmentToTag(NFCEquipmentData equipmentData) async {
    if (_isWriting) {
      throw Exception('NFC skrivning er allerede i gang');
    }

    _isWriting = true;
    final completer = Completer<bool>();
    String? writeError;

    try {
      // MINIMAL NFC DATA - Only store the equipment ID (~20 bytes)
      // All other data is looked up from database when scanned
      final nfcData = NFCData(
        id: equipmentData.id, // Only the ID - e.g., "2025-12345"
        type: 'eq',
        navn: null,
        sagId: null,
        status: null,
        data: null,
      );

      final jsonString = jsonEncode(nfcData.toJson());
      print('NFC: Starting write session for ID: ${equipmentData.id}');
      print('NFC: JSON to write: $jsonString (${jsonString.length} bytes)');

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            print('NFC: Tag discovered, checking NDEF support...');
            print('NFC: Tag data keys: ${tag.data.keys.toList()}');

            final ndef = Ndef.from(tag);

            if (ndef == null) {
              // Check if tag supports NdefFormatable (blank/unformatted tags)
              print('NFC: No NDEF found, checking for NdefFormatable...');
              final ndefFormatable = NdefFormatable.from(tag);

              if (ndefFormatable != null) {
                print('NFC: Tag is NdefFormatable - will format and write');

                // Create the NDEF message to write during format
                final ndefMessage = NdefMessage([
                  NdefRecord.createText(jsonString, languageCode: 'en'),
                ]);

                try {
                  await ndefFormatable.format(ndefMessage);
                  print('NFC: Tag formatted and written successfully!');
                  if (!completer.isCompleted) completer.complete(true);
                  return;
                } catch (formatEx) {
                  print('NFC: Format failed: $formatEx');
                  final errorStr = formatEx.toString().toLowerCase();
                  if (errorStr.contains('io_exception') || errorStr.contains('ioexception')) {
                    writeError = 'NFC kommunikationsfejl under formatering - hold telefonen stille og prøv igen';
                  } else {
                    writeError = 'Kunne ikke formatere NFC tag: $formatEx';
                  }
                  if (!completer.isCompleted) completer.complete(false);
                  return;
                }
              } else {
                print('NFC Error: Tag does not support NDEF or NdefFormatable');
                writeError = 'NFC tag understøtter ikke NDEF format';
                if (!completer.isCompleted) completer.complete(false);
                return;
              }
            }

            print('NFC: NDEF found - isWritable: ${ndef.isWritable}, maxSize: ${ndef.maxSize}');

            if (!ndef.isWritable) {
              print('NFC Error: Tag is not writable (isWritable=false)');
              writeError = 'NFC tag er skrivebeskyttet';
              if (!completer.isCompleted) completer.complete(false);
              return;
            }

            // Use the built-in createText method for proper NDEF text record formatting
            final ndefMessage = NdefMessage([
              NdefRecord.createText(jsonString, languageCode: 'en'),
            ]);

            // Check size before writing
            final messageSize = ndefMessage.byteLength;
            final maxSize = ndef.maxSize;
            print('NFC: Message size: $messageSize bytes, Tag capacity: $maxSize bytes');

            if (messageSize > maxSize) {
              writeError = 'Data er for stor til NFC tag ($messageSize > $maxSize bytes)';
              if (!completer.isCompleted) completer.complete(false);
              return;
            }

            // Write to tag - this is the critical operation
            // Retry up to 3 times for io_exception errors
            print('NFC: Starting write operation...');
            int retryCount = 0;
            const maxRetries = 3;
            bool writeSuccess = false;

            while (retryCount < maxRetries && !writeSuccess) {
              try {
                if (retryCount > 0) {
                  print('NFC: Retry attempt $retryCount...');
                  // Small delay before retry
                  await Future.delayed(const Duration(milliseconds: 100));
                }

                await ndef.write(ndefMessage);
                print('NFC: Write operation completed successfully!');
                writeSuccess = true;

                // Verify write by reading back (optional, don't fail if this fails)
                try {
                  print('NFC: Verifying write by reading back...');
                  final readBack = await ndef.read();
                  if (readBack.records.isNotEmpty) {
                    final payload = readBack.records.first.payload;
                    // Skip language code byte(s) to get the text
                    final langCodeLen = payload[0];
                    final readText = utf8.decode(payload.sublist(1 + langCodeLen));
                    print('NFC: Read back: $readText');
                    if (readText == jsonString) {
                      print('NFC: Verification successful!');
                    } else {
                      print('NFC: Warning - read back differs from written data');
                    }
                  }
                } catch (readError) {
                  print('NFC: Could not verify write (read failed): $readError');
                  // Don't fail the write operation just because verification failed
                }

                if (!completer.isCompleted) completer.complete(true);

              } catch (writeEx) {
                retryCount++;
                print('NFC: Write attempt $retryCount failed: $writeEx');
                print('NFC: Error type: ${writeEx.runtimeType}');

                final errorStr = writeEx.toString().toLowerCase();
                final isIoError = errorStr.contains('io_exception') || errorStr.contains('ioexception');

                // Only retry on io_exception, not on other errors
                if (isIoError && retryCount < maxRetries) {
                  print('NFC: Will retry write operation...');
                  continue;
                }

                // Convert to user-friendly message
                if (isIoError) {
                  writeError = 'NFC kommunikationsfejl - hold telefonen helt stille på tagget under hele skrivningen';
                } else if (errorStr.contains('taglost') || errorStr.contains('tag_lost') || errorStr.contains('tag lost')) {
                  writeError = 'NFC tag mistet - hold telefonen stille på tagget i mindst 3 sekunder';
                } else if (errorStr.contains('invalid_parameter')) {
                  writeError = 'Ugyldig NFC operation - prøv igen';
                } else {
                  writeError = 'Skrivefejl: ${writeEx.toString()}';
                }
                if (!completer.isCompleted) completer.complete(false);
              }
            }
          } catch (e) {
            print('NFC write callback error: $e');
            writeError = e.toString();
            if (!completer.isCompleted) completer.complete(false);
          }
        },
        onError: (error) async {
          print('NFC session error: ${error.type} - ${error.message}');
          writeError = 'NFC session fejl: ${error.message}';
          if (!completer.isCompleted) completer.complete(false);
        },
      );

      // Wait for completion with timeout (20 seconds for writing)
      print('NFC: Waiting for tag to be scanned...');
      bool result;
      try {
        result = await completer.future.timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            print('NFC: Timeout waiting for tag');
            writeError = 'Timeout: Hold telefonen tæt på NFC tagget';
            return false;
          },
        );
      } finally {
        // Always stop the session after we're done (success or failure)
        await _stopSessionSafely();
      }

      _isWriting = false;

      if (!result) {
        throw Exception(writeError ?? 'NFC skrivning fejlede');
      }

      print('NFC: writeEquipmentToTag returning success');
      return true;

    } catch (e) {
      _isWriting = false;
      await _stopSessionSafely();
      print('NFC write outer error: $e');
      String errorMsg = e.toString().replaceAll('Exception:', '').trim();
      throw Exception(errorMsg);
    }
  }

  // Safely stop NFC session
  Future<void> _stopSessionSafely() async {
    try {
      await NfcManager.instance.stopSession();
      print('NFC: Session stopped');
    } catch (e) {
      print('NFC: Error stopping session (may already be stopped): $e');
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

  // Reset write state - call this when an error occurs and user wants to retry
  void resetWriteState() {
    _isWriting = false;
  }

  // Reset scan state - call this when an error occurs and user wants to retry
  void resetScanState() {
    _isScanning = false;
  }
}
