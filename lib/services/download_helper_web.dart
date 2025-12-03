/// Web implementation for file downloads
/// Uses dart:html which is only available on web platform

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

/// Downloads a file on web platform
/// Creates an anchor element and triggers download
Future<void> downloadFile({
  required String content,
  required String filename,
  required String mimeType,
}) async {
  final bytes = utf8.encode(content);
  final base64str = base64Encode(bytes);

  final anchor = html.AnchorElement(
    href: 'data:$mimeType;charset=utf-8;base64,$base64str',
  );
  anchor.setAttribute('download', filename);
  anchor.click();
}

/// Downloads binary data on web platform
Future<void> downloadBinaryFile({
  required List<int> bytes,
  required String filename,
  required String mimeType,
}) async {
  final base64str = base64Encode(bytes);

  final anchor = html.AnchorElement(
    href: 'data:$mimeType;base64,$base64str',
  );
  anchor.setAttribute('download', filename);
  anchor.click();
}
