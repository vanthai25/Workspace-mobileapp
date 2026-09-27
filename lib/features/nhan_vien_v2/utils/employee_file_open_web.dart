// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

Future<void> openEmployeeFileImpl({
  required Uint8List bytes,
  required String fileName,
  String? fileType,
}) async {
  final blob = html.Blob([bytes], _contentType(fileName, fileType));
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..target = '_blank'
    ..rel = 'noopener noreferrer'
    ..click();
  unawaited(
    Future<void>.delayed(const Duration(minutes: 1)).then((_) {
      html.Url.revokeObjectUrl(url);
    }),
  );
}

String _contentType(String fileName, String? fileType) {
  final extension =
      (fileType?.trim().isNotEmpty == true
              ? fileType!
              : fileName.split('.').last)
          .replaceFirst('.', '')
          .toLowerCase();

  return switch (extension) {
    'pdf' => 'application/pdf',
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'txt' => 'text/plain',
    'doc' => 'application/msword',
    'docx' =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls' => 'application/vnd.ms-excel',
    'xlsx' =>
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    _ => 'application/octet-stream',
  };
}
