import 'dart:typed_data';

import '../screens/dialogs/dao_tao_v2/dialogs/excel_download.dart';

Future<void> openEmployeeFileImpl({
  required Uint8List bytes,
  required String fileName,
  String? fileType,
}) {
  return downloadExcelFile(bytes: bytes, fileName: fileName);
}
