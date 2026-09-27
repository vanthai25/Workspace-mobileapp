import 'dart:typed_data';

import 'employee_file_open_stub.dart'
    if (dart.library.html) 'employee_file_open_web.dart';

Future<void> openEmployeeFile({
  required Uint8List bytes,
  required String fileName,
  String? fileType,
}) {
  return openEmployeeFileImpl(
    bytes: bytes,
    fileName: fileName,
    fileType: fileType,
  );
}
