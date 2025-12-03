/// Stub implementation for non-web platforms (Android, iOS, Desktop)
/// This file is used when dart:html is not available

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads a file on mobile/desktop platforms
/// Saves to app documents directory
Future<void> downloadFile({
  required String content,
  required String filename,
  required String mimeType,
}) async {
  try {
    // Get the documents directory
    final Directory directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$filename';
    final file = File(filePath);
    await file.writeAsString(content);

    debugPrint('File saved to: $filePath');
  } catch (e) {
    debugPrint('Error saving file: $e');
    rethrow;
  }
}

/// Downloads binary data on mobile/desktop platforms
Future<void> downloadBinaryFile({
  required List<int> bytes,
  required String filename,
  required String mimeType,
}) async {
  try {
    final Directory directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$filename';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    debugPrint('Binary file saved to: $filePath');
  } catch (e) {
    debugPrint('Error saving binary file: $e');
    rethrow;
  }
}
