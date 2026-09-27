import 'dart:typed_data';

import 'excel_download_stub.dart'
    if (dart.library.html) 'excel_download_web.dart';

Future<void> downloadExcelFile({
  required Uint8List bytes,
  required String fileName,
}) {
  return downloadExcelFileImpl(bytes: bytes, fileName: fileName);
}
